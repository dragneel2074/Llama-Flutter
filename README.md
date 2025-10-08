# llama_flutter_android

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Android](https://img.shields.io/badge/Platform-Android-green.svg)](https://developer.android.com/)

Run GGUF models on Android with [llama.cpp](https://github.com/ggerganov/llama.cpp) - A simple, MIT-licensed Flutter plugin.

## Features

- **MIT Licensed** - Commercial-friendly, unlike GPL alternatives
- **Android Only** - Optimized specifically for Android (8MB vs 15MB+ multi-platform packages)
- **Android 15 Ready** - Full 16KB page size compliance
- **Simple API** - Easy-to-use Dart interface with Pigeon type safety
- **Token Streaming** - Real-time token generation with EventChannel
- **🛑 Stop Generation** - Cancel text generation mid-process on Android devices
- **18 Parameters** - Fine-grained control (temperature, penalties, mirostat, seed, etc.)
- **7 Chat Templates** - ChatML, Llama-2, Alpaca, Vicuna, Phi, Gemma, Zephyr
- **Latest llama.cpp** - Built on October 2025 llama.cpp (no patches needed)
- **ARM64 Optimized** - NEON and dot product optimizations enabled
- **18 Parameters** - Complete control: temperature, penalties, mirostat, seed, and more
- **7 Chat Templates** - ChatML, Llama-2, Alpaca, Vicuna, Phi, Gemma, Zephyr
- **Auto-Detection** - Chat templates detected from model filename

## Requirements

- Flutter 3.24.0+
- Dart SDK 3.3.0+
- Android API 26+ (Android 8.0)
- NDK r27+ (for 16KB page size support)

## Installation

Add to your \pubspec.yaml\:

\\\yaml
dependencies:
  llama_flutter_android:
    git:
      url: https://github.com/dragneel2074/llama_flutter_android.git
      ref: main
\\\

## Quick Start

### Basic Usage

\\\dart
import 'package:llama_flutter_android/llama_flutter_android.dart';

// Initialize controller
final controller = LlamaController();

// Load model
await controller.loadModel(
  modelPath: '/path/to/model.gguf',
  nThreads: 4,
  contextSize: 2048,
);

// Generate text with streaming
StreamSubscription? subscription;
subscription = controller.generate(
  prompt: 'Write a story about a robot',
  maxTokens: 512,
  temperature: 0.7,
).listen(
  (token) => print(token),  // Print each token as it arrives
  onDone: () => print('Generation complete!'),
  onError: (error) => print('Error: $error'),
);

// 🛑 STOP generation mid-process (critical for UX!)
await controller.stop();
subscription?.cancel();

// Clean up
await controller.dispose();
\\\

### Chat Mode with Templates

\\\dart
// Chat with automatic template formatting
controller.generateChat(
  messages: [
    ChatMessage(role: 'system', content: 'You are a helpful assistant'),
    ChatMessage(role: 'user', content: 'Explain quantum computing'),
  ],
  template: 'chatml', // Auto-detected if null
  temperature: 0.7,
  maxTokens: 1000,
).listen((token) => print(token));
\\\

### Advanced Parameters

\\\dart
// Fine-grained control over generation
controller.generate(
  prompt: 'Explain machine learning',
  maxTokens: 1000,
  
  // Sampling
  temperature: 0.8,      // Creativity (0.0-2.0)
  topP: 0.9,             // Nucleus sampling
  topK: 40,              // Top-K sampling
  minP: 0.05,            // Minimum probability
  
  // Penalties (reduce repetition)
  repeatPenalty: 1.2,    // Penalize repeated tokens
  frequencyPenalty: 0.5, // Penalize frequent tokens
  presencePenalty: 0.3,  // Penalize token presence
  repeatLastN: 64,       // Penalty window size
  
  // Reproducibility
  seed: 42,              // Fixed seed for same output
  
  // Mirostat (perplexity control)
  mirostat: 2,           // 0=off, 1=v1, 2=v2
  mirostatTau: 5.0,      // Target perplexity
  mirostatEta: 0.1,      // Learning rate
).listen((token) => print(token));

// 🛑 Stop anytime!
await controller.stop();
\\\

## Why llama_flutter_android?

| Feature | fllama | flutter_gemma | **llama_flutter_android** |
|---------|--------|---------------|---------------------------|
| License | GPLv2  | Apache 2.0  | **MIT**  |
| Platforms | iOS/Android/Windows | Android only | **Android only** |
| Package Size | ~15MB | ~12MB | **~8MB** |
| llama.cpp Version | Outdated | Gemma-specific | **Latest (Oct 2025)** |
| 16KB Pages | Unknown | Unknown | **Compliant**  |
| API | Complex FFI | Gemma-specific | **Simple & Generic** |

## Development Status

**Phase 1: Project Scaffold**  COMPLETE
- Flutter plugin created
- Build system configured
- llama.cpp submodule added

**Phase 2: Pigeon API** (In Progress)
- Define type-safe API
- Generate Kotlin/Dart code

**Phase 3: Kotlin Plugin** (Planned)
- Implement host API
- Create foreground service
- JNI wrapper

**Phase 4: Example App** (Planned)
- Demo chat interface
- Model download/management

## Architecture

\\\

         Flutter App (Dart)          

    llama_flutter_android.dart       
    (User-facing API)                

    Pigeon Generated Code            
    (Type-safe bridge)               

    LlamaFlutterAndroidPlugin.kt     
    (Kotlin coroutines)              

    InferenceService.kt              
    (Foreground service)             

    jni_wrapper.cpp                  
    (JNI bridge)                     

    llama.cpp                        
    (Native inference)               

\\\

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - The amazing inference engine
- [Pigeon](https://pub.dev/packages/pigeon) - Type-safe platform communication
- Inspired by research comparing fllama, flutter_gemma, and best practices

## Support

-  [Documentation](https://github.com/dragneel2074/llama_flutter_android/wiki)
-  [Issue Tracker](https://github.com/dragneel2074/llama_flutter_android/issues)
-  [Discussions](https://github.com/dragneel2074/llama_flutter_android/discussions)
