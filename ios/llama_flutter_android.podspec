Pod::Spec.new do |s|
  s.name             = 'llama_flutter_android'
  s.version          = '0.1.2'
  s.summary          = 'Run GGUF models on iOS/Android with llama.cpp'
  s.description      = 'A Flutter plugin to run GGUF quantized LLM models locally using llama.cpp, with Metal GPU acceleration on iOS.'
  s.homepage         = 'https://github.com/dragneel2074/Llama-Flutter'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'dragneel2074' => '' }
  s.source           = { :path => '.' }
  s.ios.deployment_target = '14.0'
  s.swift_version    = '5.0'

  # Plugin Swift/ObjC++ sources
  s.source_files = 'ios/Classes/**/*.{swift,h,m,mm}'

  # Shared header search paths for all subspecs
  llama_root = '$(PODS_TARGET_SRCROOT)/../android/src/main/cpp/llama.cpp'

  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS'  => '$(inherited) GGML_USE_METAL=1 NDEBUG=1',
    'OTHER_CPLUSPLUSFLAGS'          => '$(inherited) -std=c++17 -O3 -DNDEBUG -DGGML_USE_METAL=1',
    'OTHER_CFLAGS'                  => '$(inherited) -O3 -DNDEBUG -DGGML_USE_METAL=1',
    'CLANG_CXX_LANGUAGE_STANDARD'  => 'c++17',
    'HEADER_SEARCH_PATHS'           => [
      "#{llama_root}/include",
      "#{llama_root}/ggml/include",
      "#{llama_root}/src",
      "#{llama_root}/ggml/src",
      "#{llama_root}/ggml/src/ggml-cpu",
      "#{llama_root}/ggml/src/ggml-metal",
    ].join(' '),
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }

  # llama.cpp core sources
  s.subspec 'llama-core' do |ss|
    ss.source_files = '../android/src/main/cpp/llama.cpp/src/*.cpp'
    ss.compiler_flags = '-std=c++17 -O3 -DNDEBUG'
    ss.pod_target_xcconfig = {
      'HEADER_SEARCH_PATHS' => [
        "#{llama_root}/include",
        "#{llama_root}/ggml/include",
        "#{llama_root}/src",
      ].join(' '),
    }
  end

  # ggml core sources (C and C++)
  s.subspec 'ggml-core' do |ss|
    ss.source_files = [
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml.c',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-alloc.c',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-backend.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-backend-reg.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-opt.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-quants.c',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-threading.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/gguf.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-cpu/ggml-cpu.c',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-cpu/ggml-cpu.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-cpu/quants.c',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-cpu/binary-ops.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-cpu/ops.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-cpu/repack.cpp',
    ]
    ss.pod_target_xcconfig = {
      'HEADER_SEARCH_PATHS' => [
        "#{llama_root}/ggml/include",
        "#{llama_root}/ggml/src",
        "#{llama_root}/ggml/src/ggml-cpu",
      ].join(' '),
    }
  end

  # Metal GPU backend
  s.subspec 'ggml-metal' do |ss|
    ss.source_files = [
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-metal/ggml-metal.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-metal/ggml-metal-common.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-metal/ggml-metal-device.cpp',
      '../android/src/main/cpp/llama.cpp/ggml/src/ggml-metal/ggml-metal-ops.cpp',
    ]
    ss.frameworks = 'Metal', 'MetalKit', 'MetalPerformanceShaders'
    ss.resource_bundles = {
      'llama_flutter_android_metal' => [
        '../android/src/main/cpp/llama.cpp/ggml/src/ggml-metal/ggml-metal.metal',
      ]
    }
    ss.pod_target_xcconfig = {
      'HEADER_SEARCH_PATHS' => [
        "#{llama_root}/ggml/include",
        "#{llama_root}/ggml/src",
        "#{llama_root}/ggml/src/ggml-metal",
      ].join(' '),
    }
  end

  s.frameworks = 'Accelerate', 'Foundation'
  s.libraries  = 'c++'
end
