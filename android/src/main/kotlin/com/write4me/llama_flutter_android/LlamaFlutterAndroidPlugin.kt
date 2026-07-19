package com.write4me.llama_flutter_android

import android.app.ActivityManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.*
import java.util.concurrent.atomic.AtomicBoolean

class LlamaFlutterAndroidPlugin : FlutterPlugin, LlamaHostApi {
    private lateinit var context: Context
    private lateinit var flutterApi: LlamaFlutterApi
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var generationJob: Job? = null
    private val isModelLoaded = AtomicBoolean(false)
    private val isStopping = AtomicBoolean(false)
    private var currentModelPath: String? = null

    // FIFO main-thread delivery. The previous per-token
    // scope.launch { withContext(Main) { ... } } pattern created a NEW
    // unordered coroutine per token — tokens could reach Dart out of order
    // and onDone could beat the last tokens. Handler.post is strictly FIFO
    // and far cheaper at 20+ tokens/sec.
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        // llama native libs are built for arm64-v8a only. On 32-bit devices
        // loadLibrary throws UnsatisfiedLinkError, and doing that in a static
        // initializer turns it into NoClassDefFoundError at plugin
        // registration — an app-killing startup crash (seen in production).
        // Load safely and let every native entry point no-op instead.
        @JvmStatic
        val nativeLibAvailable: Boolean = try {
            System.loadLibrary("llama_jni")
            true
        } catch (t: Throwable) {
            android.util.Log.e(
                "LlamaFlutterAndroid",
                "llama_jni unavailable — Local AI disabled on this device", t)
            false
        }

        private const val UNSUPPORTED_MSG =
            "Local AI is not supported on this device."
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterApi = LlamaFlutterApi(binding.binaryMessenger)
        LlamaHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        isStopping.set(true)
        if (nativeLibAvailable) nativeStop()
        // Bounded wait for the native call to return before freeing the
        // model — freeing mid-decode is a use-after-free crash. Short cap:
        // this runs on the platform thread during engine teardown.
        runBlocking { withTimeoutOrNull(2_000) { generationJob?.join() } }
        generationJob?.cancel()
        scope.cancel()
        if (isModelLoaded.get()) {
            nativeFreeModel()
        }
        LlamaHostApi.setUp(binding.binaryMessenger, null)
    }

    override fun loadModel(config: ModelConfig, callback: (Result<Unit>) -> Unit) {
        if (!nativeLibAvailable) {
            callback(Result.failure(UnsupportedOperationException(UNSUPPORTED_MSG)))
            return
        }
        if (generationJob?.isActive == true) {
            callback(Result.failure(
                IllegalStateException("Cannot load a model while generating")))
            return
        }
        scope.launch {
            try {
                // Load model with progress callback
                nativeLoadModel(
                    config.modelPath,
                    config.nThreads,
                    config.contextSize,
                    config.nGpuLayers ?: 0L
                ) { progress ->
                    mainHandler.post {
                        flutterApi.onLoadProgress(progress) { }
                    }
                }

                currentModelPath = config.modelPath
                isModelLoaded.set(true)
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                scope.launch {
                    withContext(Dispatchers.Main) {
                        flutterApi.onError(e.message ?: "Failed to load model") { result ->
                            // Handle result if needed
                        }
                        callback(Result.failure(e))
                    }
                }
            }
        }
    }

    override fun generate(request: GenerateRequest, callback: (Result<Unit>) -> Unit) {
        if (!isModelLoaded.get()) {
            callback(Result.failure(IllegalStateException("Model not loaded")))
            return
        }

        isStopping.set(false)
        generationJob = scope.launch {
            try {
                nativeGenerate(
                    request.prompt,
                    request.maxTokens,
                    request.temperature,
                    request.topP,
                    request.topK,
                    request.minP,
                    request.typicalP,
                    request.repeatPenalty,
                    request.frequencyPenalty,
                    request.presencePenalty,
                    request.repeatLastN,
                    request.mirostat,
                    request.mirostatTau,
                    request.mirostatEta,
                    request.seed ?: -1L,  // Use -1 for random seed
                    request.penalizeNewline
                ) { token ->
                    if (!isStopping.get()) {
                        mainHandler.post {
                            flutterApi.onToken(token) { }
                        }
                    }
                }

                // ALWAYS deliver a terminal event — suppressing onDone after
                // stop() left the Dart stream open forever and the controller
                // stuck in "Already generating".
                mainHandler.post {
                    flutterApi.onDone { }
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                mainHandler.post {
                    if (isStopping.get()) {
                        // Intentional cancellation — terminal done, not error.
                        flutterApi.onDone { }
                        callback(Result.success(Unit))
                    } else {
                        flutterApi.onError(e.message ?: "Generation failed") { }
                        callback(Result.failure(e))
                    }
                }
            }
        }
    }

    override fun stop(callback: (Result<Unit>) -> Unit) {
        isStopping.set(true)
        generationJob?.cancel()
        if (nativeLibAvailable) nativeStop()
        callback(Result.success(Unit))
    }

    override fun dispose(callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                stop { }
                // Wait for the generation coroutine to exit the native call
                // before freeing the model — nativeFreeModel() during a
                // running llama_decode is a use-after-free crash. Bounded so
                // a hung native call can't wedge dispose forever.
                withTimeoutOrNull(10_000) { generationJob?.join() }
                if (isModelLoaded.get()) {
                    nativeFreeModel()
                    isModelLoaded.set(false)
                }

                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun generateChat(request: ChatRequest, callback: (Result<Unit>) -> Unit) {
        if (!isModelLoaded.get()) {
            callback(Result.failure(IllegalStateException("Model not loaded")))
            return
        }

        isStopping.set(false)
        generationJob = scope.launch {
            try {
                // Format the chat messages using the template manager
                val formattedPrompt = ChatTemplateManager.formatMessages(
                    request.messages.map { msg -> TemplateChatMessage(msg.role, msg.content) },
                    request.template,
                    currentModelPath
                )

                nativeGenerate(
                    formattedPrompt,
                    request.maxTokens.toLong(),
                    request.temperature.toDouble(),
                    request.topP.toDouble(),
                    request.topK.toLong(),
                    request.minP.toDouble(),
                    request.typicalP.toDouble(),
                    request.repeatPenalty.toDouble(),
                    request.frequencyPenalty.toDouble(),
                    request.presencePenalty.toDouble(),
                    request.repeatLastN.toLong(),
                    request.mirostat.toLong(),
                    request.mirostatTau.toDouble(),
                    request.mirostatEta.toDouble(),
                    request.seed ?: -1L,  // Use -1 for random seed
                    request.penalizeNewline
                ) { token ->
                    if (!isStopping.get()) {
                        mainHandler.post {
                            flutterApi.onToken(token) { }
                        }
                    }
                }

                // ALWAYS deliver a terminal event — suppressing onDone after
                // stop() left the Dart stream open forever and the controller
                // stuck in "Already generating".
                mainHandler.post {
                    flutterApi.onDone { }
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                mainHandler.post {
                    if (isStopping.get()) {
                        // Intentional cancellation — terminal done, not error.
                        flutterApi.onDone { }
                        callback(Result.success(Unit))
                    } else {
                        flutterApi.onError(e.message ?: "Generation failed") { }
                        callback(Result.failure(e))
                    }
                }
            }
        }
    }

    override fun getSupportedTemplates(): List<String> {
        return ChatTemplateManager.getSupportedTemplates()
    }

    override fun isModelLoaded(): Boolean {
        return isModelLoaded.get()
    }

    override fun getContextInfo(): ContextInfo {
        if (!nativeLibAvailable) {
            return ContextInfo(tokensUsed = 0L, contextSize = 0L, usagePercentage = 0.0)
        }
        val tokensUsed = nativeGetTokensUsed().toLong()
        val contextSize = nativeGetContextSize().toLong()
        val usagePercentage = if (contextSize > 0) {
            (tokensUsed.toDouble() / contextSize.toDouble() * 100.0)
        } else {
            0.0
        }
        
        return ContextInfo(
            tokensUsed = tokensUsed,
            contextSize = contextSize,
            usagePercentage = usagePercentage
        )
    }

    override fun clearContext(callback: (Result<Unit>) -> Unit) {
        if (!nativeLibAvailable) {
            callback(Result.success(Unit))
            return
        }
        scope.launch {
            try {
                nativeClearContext()
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun setSystemPromptLength(length: Long) {
        if (!nativeLibAvailable) return
        nativeSetSystemPromptLength(length.toInt())
    }

    /**
     * Register a custom chat template
     * Allows users to provide their own template format at runtime
     */
    override fun registerCustomTemplate(name: String, content: String) {
        ChatTemplateManager.registerCustomTemplate(name, content)
    }

    /**
     * Unregister a custom chat template
     * Removes a previously registered custom template
     */
    override fun unregisterCustomTemplate(name: String) {
        ChatTemplateManager.unregisterCustomTemplate(name)
    }

    override fun detectGpu(callback: (Result<GpuInfo>) -> Unit) {
        if (!nativeLibAvailable) {
            callback(Result.success(GpuInfo(
                vulkanSupported = false,
                gpuName = "None",
                vulkanApiVersion = -1L,
                deviceLocalMemoryBytes = -1L,
                freeRamBytes = -1L,
                recommendedGpuLayers = 0L
            )))
            return
        }
        scope.launch {
            try {
                val outStats = LongArray(2) { -1L }
                val gpuName: String? = nativeDetectGpu(outStats)
                val vulkanSupported = gpuName != null
                val apiVersion = outStats[0]
                val deviceLocalMemory = outStats[1]

                val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val memInfo = ActivityManager.MemoryInfo()
                activityManager.getMemoryInfo(memInfo)
                val freeRamBytes = memInfo.availMem

                val recommendedGpuLayers = computeRecommendedLayers(
                    vulkanSupported = vulkanSupported,
                    gpuName = gpuName ?: "",
                    freeRamBytes = freeRamBytes,
                    deviceLocalMemoryBytes = deviceLocalMemory
                )

                withContext(Dispatchers.Main) {
                    callback(Result.success(GpuInfo(
                        vulkanSupported = vulkanSupported,
                        gpuName = gpuName ?: "None",
                        vulkanApiVersion = apiVersion,
                        deviceLocalMemoryBytes = deviceLocalMemory,
                        freeRamBytes = freeRamBytes,
                        recommendedGpuLayers = recommendedGpuLayers.toLong()
                    )))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.success(GpuInfo(
                        vulkanSupported = false,
                        gpuName = "None",
                        vulkanApiVersion = -1L,
                        deviceLocalMemoryBytes = -1L,
                        freeRamBytes = -1L,
                        recommendedGpuLayers = 0L
                    )))
                }
            }
        }
    }

    private fun computeRecommendedLayers(
        vulkanSupported: Boolean,
        gpuName: String,
        freeRamBytes: Long,
        deviceLocalMemoryBytes: Long
    ): Int {
        val GB = 1_073_741_824L
        val safeRam = (freeRamBytes * 0.7).toLong()
        return when {
            !vulkanSupported -> 0
            safeRam < GB -> 0                                          // < 1 GB — truly too low
            safeRam < 2 * GB && deviceLocalMemoryBytes < 3 * GB -> 0  // low RAM + low VRAM
            safeRam < 3 * GB || deviceLocalMemoryBytes < 2 * GB -> 16 // partial offload
            else -> 99                                                  // full offload
        }
    }

    // Native methods
    private external fun nativeLoadModel(
        path: String,
        nThreads: Long,
        contextSize: Long,
        nGpuLayers: Long,
        progressCallback: (Double) -> Unit
    )

    private external fun nativeGenerate(
        prompt: String,
        maxTokens: Long,
        temperature: Double,
        topP: Double,
        topK: Long,
        minP: Double,
        typicalP: Double,
        repeatPenalty: Double,
        frequencyPenalty: Double,
        presencePenalty: Double,
        repeatLastN: Long,
        mirostat: Long,
        mirostatTau: Double,
        mirostatEta: Double,
        seed: Long,
        penalizeNewline: Boolean,
        tokenCallback: (String) -> Unit
    )

    private external fun nativeStop()
    private external fun nativeFreeModel()
    private external fun nativeGetTokensUsed(): Int
    private external fun nativeGetContextSize(): Int
    private external fun nativeClearContext()
    private external fun nativeSetSystemPromptLength(length: Int)
    private external fun nativeDetectGpu(outStats: LongArray): String?
    // outStats[0] = vulkanApiVersion, outStats[1] = deviceLocalMemoryBytes
}