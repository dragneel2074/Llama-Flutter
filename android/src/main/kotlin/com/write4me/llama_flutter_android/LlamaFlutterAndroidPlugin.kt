package com.write4me.llama_flutter_android

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
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

    companion object {
        init {
            System.loadLibrary("llama_jni")
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterApi = LlamaFlutterApi(binding.binaryMessenger)
        LlamaHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        scope.cancel()
        if (isModelLoaded.get()) {
            nativeFreeModel()
        }
        LlamaHostApi.setUp(binding.binaryMessenger, null)
    }

    override fun loadModel(config: ModelConfig, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                // Start foreground service for long-running task
                val intent = Intent(context, InferenceService::class.java)
                ContextCompat.startForegroundService(context, intent)

                // Load model with progress callback
                nativeLoadModel(
                    config.modelPath,
                    config.nThreads,
                    config.contextSize,
                    config.nGpuLayers ?: 0L
                ) { progress ->
                    scope.launch {
                        withContext(Dispatchers.Main) {
                            flutterApi.onLoadProgress(progress) { result ->
                                // Handle result if needed
                            }
                        }
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
                        scope.launch {
                            withContext(Dispatchers.Main) {
                                flutterApi.onToken(token) { result ->
                                    // Handle result if needed
                                }
                            }
                        }
                    }
                }

                if (!isStopping.get()) {
                    scope.launch {
                        withContext(Dispatchers.Main) {
                            flutterApi.onDone { result ->
                                // Handle result if needed
                            }
                        }
                    }
                }

                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                if (!isStopping.get()) {
                    scope.launch {
                        withContext(Dispatchers.Main) {
                            flutterApi.onError(e.message ?: "Generation failed") { result ->
                                // Handle result if needed
                            }
                            callback(Result.failure(e))
                        }
                    }
                }
            }
        }
    }

    override fun stop(callback: (Result<Unit>) -> Unit) {
        isStopping.set(true)
        generationJob?.cancel()
        nativeStop()
        callback(Result.success(Unit))
    }

    override fun dispose(callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                stop { }
                if (isModelLoaded.get()) {
                    nativeFreeModel()
                    isModelLoaded.set(false)
                }
                
                // Stop foreground service
                val intent = Intent(context, InferenceService::class.java)
                context.stopService(intent)
                
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
                        scope.launch {
                            withContext(Dispatchers.Main) {
                                flutterApi.onToken(token) { result ->
                                    // Handle result if needed
                                }
                            }
                        }
                    }
                }

                if (!isStopping.get()) {
                    scope.launch {
                        withContext(Dispatchers.Main) {
                            flutterApi.onDone { result ->
                                // Handle result if needed
                            }
                        }
                    }
                }

                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                if (!isStopping.get()) {
                    scope.launch {
                        withContext(Dispatchers.Main) {
                            flutterApi.onError(e.message ?: "Generation failed") { result ->
                                // Handle result if needed
                            }
                            callback(Result.failure(e))
                        }
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
}