import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  kotlinOut: 'android/src/main/kotlin/com/write4me/llama_flutter_android/LlamaHostApi.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.write4me.llama_flutter_android',
  ),
  dartOut: 'lib/src/llama_api.dart',
  dartOptions: DartOptions(),
))
  
/// Configuration for model loading
class ModelConfig {
  final String modelPath;
  final int nThreads;
  final int contextSize;
  final int? nGpuLayers;
  
  ModelConfig({
    required this.modelPath,
    this.nThreads = 4,
    this.contextSize = 2048,
    this.nGpuLayers,
  });
}

/// Chat message
class ChatMessage {
  /// Role: 'system', 'user', or 'assistant'
  final String role;
  final String content;
  
  ChatMessage({
    required this.role,
    required this.content,
  });
}

/// Request for text generation
class GenerateRequest {
  final String prompt;
  final int maxTokens;
  
  // Sampling parameters
  final double temperature;
  final double topP;
  final int topK;
  final double minP;
  final double typicalP;
  
  // Penalties
  final double repeatPenalty;
  final double frequencyPenalty;
  final double presencePenalty;
  final int repeatLastN;
  
  // Mirostat sampling
  final int mirostat;
  final double mirostatTau;
  final double mirostatEta;
  
  // Other
  final int? seed;
  final bool penalizeNewline;
  
  GenerateRequest({
    required this.prompt,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.minP = 0.05,
    this.typicalP = 1.0,
    this.repeatPenalty = 1.1,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.repeatLastN = 64,
    this.mirostat = 0,
    this.mirostatTau = 5.0,
    this.mirostatEta = 0.1,
    this.seed,
    this.penalizeNewline = true,
  });
}

/// Request for chat generation with template formatting
class ChatRequest {
  final List<ChatMessage> messages;
  final String? template; // null = auto-detect from model
  final int maxTokens;
  
  // Sampling parameters
  final double temperature;
  final double topP;
  final int topK;
  final double minP;
  final double typicalP;
  
  // Penalties
  final double repeatPenalty;
  final double frequencyPenalty;
  final double presencePenalty;
  final int repeatLastN;
  
  // Mirostat sampling
  final int mirostat;
  final double mirostatTau;
  final double mirostatEta;
  
  // Other
  final int? seed;
  final bool penalizeNewline;
  
  ChatRequest({
    required this.messages,
    this.template,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.minP = 0.05,
    this.typicalP = 1.0,
    this.repeatPenalty = 1.1,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.repeatLastN = 64,
    this.mirostat = 0,
    this.mirostatTau = 5.0,
    this.mirostatEta = 0.1,
    this.seed,
    this.penalizeNewline = true,
  });
}

/// Host API (Dart calls Kotlin)
@HostApi()
abstract class LlamaHostApi {
  /// Load a GGUF model
  @async
  void loadModel(ModelConfig config);
  
  /// Start text generation (tokens streamed via FlutterApi)
  @async
  void generate(GenerateRequest request);
  
  /// Start chat generation with automatic template formatting
  @async
  void generateChat(ChatRequest request);
  
  /// Get list of supported chat templates
  List<String> getSupportedTemplates();
  
  /// Stop current generation
  @async
  void stop();
  
  /// Unload model and free resources
  @async
  void dispose();
  
  /// Check if model is loaded
  bool isModelLoaded();
}

/// Flutter API (Kotlin calls Dart)
@FlutterApi()
abstract class LlamaFlutterApi {
  /// Stream token to Dart
  void onToken(String token);
  
  /// Generation completed
  void onDone();
  
  /// Error occurred
  void onError(String error);
  
  /// Loading progress (0.0 to 1.0)
  void onLoadProgress(double progress);
}