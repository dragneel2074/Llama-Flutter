# Chat App - Local LLM on Android

A Flutter chat application that runs large language models (LLMs) locally on Android devices using GGUF format models.

## Features

✨ **Run LLMs Locally** - No internet required, complete privacy  
🤖 **Auto Chat Templates** - Supports 11+ model families (Qwen, Llama-3, Mistral, etc.)  
💬 **Multi-turn Conversations** - Full context-aware chat with history  
⚡ **Streaming Responses** - Real-time token generation  
🛑 **Stop Generation** - Cancel responses mid-generation  
📱 **Modern UI** - Clean chat bubbles with typing indicators  
📁 **Local File Picker** - Load models from device storage  

## Supported Models

The app automatically detects and applies the correct chat template for:

- **Qwen / Qwen2** (ChatML)
- **Llama-3** (Llama-3 format)  
- **Llama-2** (Llama-2 format)
- **QwQ-32B** (QwQ format with thinking)
- **Mistral** (Mistral format)
- **DeepSeek** (DeepSeek format)
- **Phi-2/3** (Phi format)
- **Gemma** (Gemma format)
- **Alpaca, Vicuna** (and more)

## Quick Start

### 1. Requirements

- Flutter SDK 3.9.2+
- Dart SDK 3.3.0+
- Android device/emulator with API 26+
- NDK r27+ (for 16KB page support)
- A GGUF model file (e.g., Qwen2-0.5B-Instruct-Q4_K_M.gguf)

### 2. Installation

```bash
# Clone the repository
cd chat_app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### 3. Load a Model

1. Tap **"Load from Local"**
2. Browse to your GGUF model file
3. Wait for model to load
4. Start chatting!

## Usage

### Basic Chat

```
You: Hello!
AI: Hi there! How can I help you today?

You: What is Flutter?
AI: Flutter is a UI framework by Google for building natively compiled...
```

### Stop Generation

Tap the red **Stop** button while AI is responding to cancel generation. Partial responses are saved to chat history.

### Clear Chat

Tap **Clear Chat** in the app bar to reset the conversation (keeps system message).

## Architecture

### Core Components

**`lib/services/chat_service.dart`**
- Manages LlamaController lifecycle
- Maintains conversation history with `ChatMessage` objects
- Handles automatic chat template formatting
- Supports streaming token generation
- Implements stop/cancel generation

**`lib/services/model_download_service.dart`**
- File picker integration for local models
- Model validation (size >10 MB)
- Path management

**`lib/main.dart`**
- Modern chat UI with bubbles
- Typing indicators during generation
- Send/stop button toggle
- Clear chat with confirmation

### Chat Template System

The app uses the production-ready chat template system from `llama_flutter_android`:

```dart
// Automatic template detection
final messages = [
  ChatMessage(role: 'system', content: 'You are helpful.'),
  ChatMessage(role: 'user', content: 'Hello!'),
];

final stream = controller.generateChat(
  messages: messages,  // Template auto-detected from filename
  maxTokens: 512,
  temperature: 0.7,
);
```

See [CHAT_TEMPLATES.md](CHAT_TEMPLATES.md) for complete documentation.

## Configuration

### Model Parameters

In `lib/services/chat_service.dart`:

```dart
await _llama!.loadModel(
  modelPath: modelPath,
  threads: 4,           // CPU threads
  contextSize: 1024,    // Context window
);
```

### Generation Parameters

```dart
final stream = _llama!.generateChat(
  messages: _conversationHistory,
  maxTokens: 512,       // Max tokens to generate
  temperature: 0.7,     // Creativity (0.0-2.0)
  topP: 0.9,           // Nucleus sampling
);
```

### System Message

```dart
// Custom system prompt
await chatService.initialize(
  systemMessage: 'You are a coding assistant expert in Dart and Flutter.'
);
```

## Troubleshooting

### Model Won't Load

**Error:** "Model already loaded"  
**Solution:** App automatically disposes old models. If error persists, restart the app.

**Error:** "File size too small"  
**Solution:** Ensure your GGUF file is >10 MB and not corrupted.

### Gibberish Responses

**Cause:** Wrong chat template  
**Solution:** Most models are auto-detected. For custom models, check the model card for template requirements.

### Build Errors

**NDK Issues:**  
Ensure NDK r27+ is installed via Android Studio SDK Manager.

**CMake Errors:**  
```bash
flutter clean
flutter pub get
flutter run
```

## Documentation

- [Chat Templates Guide](CHAT_TEMPLATES.md) - Complete chat template documentation
- [Plugin Source](../llama_flutter_android/) - llama_flutter_android plugin

## Performance

**Tested Models:**
- Qwen2-0.5B (500 MB) - ~5-10 tokens/sec on mid-range phones
- Qwen2-1.5B (1.5 GB) - ~3-7 tokens/sec
- Llama-3-8B (8 GB) - Requires high-end device with 12+ GB RAM

**Tips:**
- Use Q4_K_M quantization for best size/quality balance
- Smaller models (0.5B-1.5B) work well on most devices
- Enable 4 threads for optimal CPU usage

## License

This project is a demonstration app for the `llama_flutter_android` plugin.

## Credits

- Built with [Flutter](https://flutter.dev/)
- Uses [llama.cpp](https://github.com/ggerganov/llama.cpp) via `llama_flutter_android`
- Chat templates based on official model documentation

## Getting Started with Flutter

New to Flutter? Check these resources:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter Documentation](https://docs.flutter.dev/)
