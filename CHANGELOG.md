## 0.1.2 (March 5, 2026)

### Updated
- Vendored llama.cpp updated to release b8201 (March 4, 2026)

## 0.1.1-dev (February 8, 2026)

### Updated
- Vendored llama.cpp updated to release b7966 (Feb 7, 2026)

## 0.1.0-dev (October 8, 2025)

### Added
- Initial Android-only Flutter plugin implementation
- Pigeon-based type-safe API for Dart ↔ Kotlin communication
- llama.cpp integration via JNI with latest API (Oct 2025)
- Streaming token generation with real-time callbacks
- Foreground service for long-running inference
- Android 15 compliance (16KB page size support)
- ARM64 optimizations (NEON, dot product instructions)
- Progress tracking for model loading
- User-friendly `LlamaController` API
- Example chat application
- **Comprehensive chat template system** with 7 formats (ChatML, Llama-2, Alpaca, Vicuna, Phi, Gemma)
- **Extended parameter support** - 18 generation parameters for fine-grained control
- Complete parameter documentation (`PARAMETERS_GUIDE.md`)
- Feature reference guide (`FEATURES.md`)

### Features
- **Model Management**
  - Load GGUF models from filesystem
  - Configurable context size (default 2048)
  - Thread count configuration (default 4)
  - Optional GPU layer offloading

- **Text Generation**
  - Stream tokens in real-time
  - **18 configurable parameters:**
    - Basic: maxTokens
    - Sampling: temperature, topP, topK, minP, typicalP
    - Penalties: repeatPenalty, frequencyPenalty, presencePenalty, repeatLastN, penalizeNewline
    - Mirostat: mirostat (0/1/2), mirostatTau, mirostatEta
    - Reproducibility: seed
  - Cancellation support
  - EOS detection

- **Chat Template System**
  - 7 supported templates: ChatML (Qwen/Llama-3), Llama-2, Alpaca, Vicuna, Phi, Gemma
  - Auto-detection based on model filename
  - Proper system prompt integration
  - Multi-turn conversation support
  - Extensible template architecture

- **Platform Integration**
  - Foreground service with notification
  - `FOREGROUND_SERVICE_SPECIAL_USE` permission
  - Proper lifecycle management
  - Memory-efficient mmap-based model loading

### Fixed
- **llama.cpp API Compatibility (Critical)**
  - Updated to October 2025 llama.cpp API
  - Removed dependency on common library (simplified to raw llama.cpp API only)
  - Fixed tokenization negative count issue (llama_tokenize returns -count when tokens=NULL)
  - Manual batch operations instead of helper functions
  - Comprehensive sampler chain implementation with penalties, mirostat, and standard samplers
  - Fixed 8 compilation errors caused by llama.cpp API changes
  
- **Chat Template Issues**
  - Resolved ChatMessage redeclaration conflict (Pigeon vs custom class)
  - Renamed internal class to TemplateChatMessage
  - Fixed gibberish output by implementing proper chat formatting

### Technical Details
- **Build System**
  - Kotlin DSL (build.gradle.kts)
  - CMake 3.22.1 with C++17
  - Android Gradle Plugin 8.9.1
  - Kotlin 2.1.0
  - NDK r27 for 16KB page size compliance

- **Dependencies**
  - Pigeon 22.7.4 for code generation
  - Kotlin Coroutines 1.9.0
  - llama.cpp (latest, Oct 2025)

### Known Limitations
- Android-only (no iOS, Windows, macOS support)
- ARM64-only (no x86_64 support)
- Minimum SDK: Android 8.0 (API 26)
- Requires ~4-8GB RAM for typical models

### Documentation
- Comprehensive README.md with feature comparison
- Research comparison summary (ChatGPT, Gemini, Kimi)
- Implementation plan and checklist
- Quick start guide
- Contributing guidelines
- Fixes documentation (FIXES_APPLIED.md)
- MIT License (commercial-friendly)

### Notes
This is a development release. The API may change before 1.0.0. Testing on real devices is recommended before production use.

## 0.1.1 (October 11, 2025)

### Changed
- Updated package description on pub.dev to clarify Android-only plugin scope and features
