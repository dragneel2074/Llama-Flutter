## 0.2.6 (July 20, 2026)

### Fixed
- **Use-after-free crash on `dispose()`/engine detach during generation**:
  the model could be freed while `llama_decode` was still running on another
  thread. Both paths now wait (bounded) for the generation job to finish
  before `nativeFreeModel()`.
- **Streams now always terminate**: `onDone` was suppressed after `stop()`
  and errors never closed the Dart stream, leaving the controller
  permanently stuck in "Already generating". Every generation now ends with
  a terminal `onDone`/`onError`, and the Dart controller resets state on
  both.
- **Token ordering**: per-token delivery used a new unordered coroutine per
  token (tokens could reach Dart scrambled; `onDone` could beat the last
  tokens). Replaced with strictly-FIFO main-thread `Handler.post`, which is
  also much cheaper at 20+ tokens/sec.
- `loadModel()` while a generation is running is now rejected instead of
  racing the active context.

### Changed
- Vendored llama.cpp updated to b10068 (note: prebuilt `.so` binaries are
  rebuilt separately; a source bump alone does not change shipped natives).

## 0.2.5 (July 20, 2026)

### Fixed
- **Startup crash on unsupported ABIs**: `System.loadLibrary("llama_jni")` in a
  static initializer turned `UnsatisfiedLinkError` into `NoClassDefFoundError`
  at plugin registration on devices without arm64 (app-killing crash). The
  library now loads into a `nativeLibAvailable` flag and all native entry
  points fail gracefully with "Local AI is not supported on this device."

### Changed
- **Removed the foreground service and `FOREGROUND_SERVICE_SPECIAL_USE`
  permission** (thanks @heckmon, #1). The plugin no longer forces a
  special-use FGS declaration onto every consuming app's Play Console
  submission. Apps that need inference to survive backgrounding should run
  their own foreground service.
- README: documented the R8/proguard keep rules consumers need when
  `minifyEnabled` is on (thanks @heckmon).

## 0.2.4 (July 5, 2026)

### Fixed
- Removed the Mali GPU blanket ban from `detectGpu` layer recommendations
- Bumped vendored llama.cpp to b8851

## 0.2.3 (April 20, 2026)

### Fixed
- Disable `GGML_VULKAN` — NDK 27 lacks `vulkan.hpp` and the shader compiler (`vulkan-shaders-gen`) fails to build on Windows cross-compile
- `detectGpu()` still works fully via the C Vulkan header; GPU layer offloading will be re-enabled when a Linux CI with a proper Vulkan SDK is available

## 0.2.2 (April 19, 2026)

### Fixed
- Fix Vulkan build on Windows when cross-compiling for Android — forward `CMAKE_MAKE_PROGRAM` (Ninja path) into the `vulkan-shaders-gen` ExternalProject sub-build

## 0.2.1 (April 19, 2026)

### Fixed
- Published package now includes `CMakeLists.txt` — wildcard `*.txt` in `.pubignore` was incorrectly excluding it, causing empty build directory

## 0.2.0 (April 18, 2026)

### Added
- **Vulkan GPU backend** — `GGML_VULKAN` now compiled into the native `.so`; `gpuLayers` parameter is no longer silently ignored on supported devices
- **`detectGpu()` API** — new `LlamaController.detectGpu()` method returns `GpuInfo` with:
  - `vulkanSupported` — true only when Vulkan instance **and** a compute queue are confirmed
  - `gpuName` — real device name from Vulkan (e.g. "Adreno (TM) 740")
  - `vulkanApiVersion` — Vulkan API version integer
  - `deviceLocalMemoryBytes` — largest device-local heap (note: equals system RAM on Android UMA devices)
  - `freeRamBytes` — current free system RAM via `ActivityManager`
  - `recommendedGpuLayers` — non-binding suggestion (0, 16, or 99); caller always decides final `gpuLayers`
- **Smart GPU heuristic** — recommendation accounts for Mali GPU instability, 0.7× RAM safety factor, and device-local memory size
- **`GpuInfo`** exported from the public package API

### Notes
- Vulkan detection does not guarantee GPU is faster than CPU for a given model — `vulkanSupported` answers "can I try GPU?", not "will GPU be faster?"
- Mali GPUs default to `recommendedGpuLayers: 0` due to known llama.cpp Vulkan instability on that architecture

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
