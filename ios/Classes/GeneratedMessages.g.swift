// Hand-written Pigeon Swift bridge — mirrors LlamaHostApi.kt exactly.
// Channel names MUST match the Kotlin/Dart generated code.
import Flutter
import Foundation

// MARK: - Data classes

struct ModelConfig {
    var modelPath: String
    var nThreads: Int64
    var contextSize: Int64
    var nGpuLayers: Int64?

    static func fromList(_ list: [Any?]) -> ModelConfig {
        func toI64(_ v: Any?) -> Int64 { v is Int ? Int64(v as! Int) : v as! Int64 }
        return ModelConfig(
            modelPath: list[0] as! String,
            nThreads: toI64(list[1]),
            contextSize: toI64(list[2]),
            nGpuLayers: list[3] == nil ? nil : toI64(list[3])
        )
    }
    func toList() -> [Any?] { [modelPath, nThreads, contextSize, nGpuLayers] }
}

struct ChatMessage {
    var role: String
    var content: String

    static func fromList(_ list: [Any?]) -> ChatMessage {
        return ChatMessage(role: list[0] as! String, content: list[1] as! String)
    }
    func toList() -> [Any?] { [role, content] }
}

struct GenerateRequest {
    var prompt: String
    var maxTokens: Int64
    var temperature: Double
    var topP: Double
    var topK: Int64
    var minP: Double
    var typicalP: Double
    var repeatPenalty: Double
    var frequencyPenalty: Double
    var presencePenalty: Double
    var repeatLastN: Int64
    var mirostat: Int64
    var mirostatTau: Double
    var mirostatEta: Double
    var seed: Int64?
    var penalizeNewline: Bool

    static func fromList(_ list: [Any?]) -> GenerateRequest {
        func toI64(_ v: Any?) -> Int64 { v is Int ? Int64(v as! Int) : v as! Int64 }
        return GenerateRequest(
            prompt: list[0] as! String,
            maxTokens: toI64(list[1]),
            temperature: list[2] as! Double,
            topP: list[3] as! Double,
            topK: toI64(list[4]),
            minP: list[5] as! Double,
            typicalP: list[6] as! Double,
            repeatPenalty: list[7] as! Double,
            frequencyPenalty: list[8] as! Double,
            presencePenalty: list[9] as! Double,
            repeatLastN: toI64(list[10]),
            mirostat: toI64(list[11]),
            mirostatTau: list[12] as! Double,
            mirostatEta: list[13] as! Double,
            seed: list[14] == nil ? nil : toI64(list[14]),
            penalizeNewline: list[15] as! Bool
        )
    }
}

struct ChatRequest {
    var messages: [ChatMessage]
    var template: String?
    var maxTokens: Int64
    var temperature: Double
    var topP: Double
    var topK: Int64
    var minP: Double
    var typicalP: Double
    var repeatPenalty: Double
    var frequencyPenalty: Double
    var presencePenalty: Double
    var repeatLastN: Int64
    var mirostat: Int64
    var mirostatTau: Double
    var mirostatEta: Double
    var seed: Int64?
    var penalizeNewline: Bool

    static func fromList(_ list: [Any?]) -> ChatRequest {
        func toI64(_ v: Any?) -> Int64 { v is Int ? Int64(v as! Int) : v as! Int64 }
        let rawMessages = list[0] as! [Any?]
        let messages = rawMessages.map { ChatMessage.fromList($0 as! [Any?]) }
        return ChatRequest(
            messages: messages,
            template: list[1] as? String,
            maxTokens: toI64(list[2]),
            temperature: list[3] as! Double,
            topP: list[4] as! Double,
            topK: toI64(list[5]),
            minP: list[6] as! Double,
            typicalP: list[7] as! Double,
            repeatPenalty: list[8] as! Double,
            frequencyPenalty: list[9] as! Double,
            presencePenalty: list[10] as! Double,
            repeatLastN: toI64(list[11]),
            mirostat: toI64(list[12]),
            mirostatTau: list[13] as! Double,
            mirostatEta: list[14] as! Double,
            seed: list[15] == nil ? nil : toI64(list[15]),
            penalizeNewline: list[16] as! Bool
        )
    }
}

struct ContextInfo {
    var tokensUsed: Int64
    var contextSize: Int64
    var usagePercentage: Double

    func toList() -> [Any?] { [tokensUsed, contextSize, usagePercentage] }
}

// MARK: - Host API protocol (Dart calls Swift)

protocol LlamaHostApiProtocol {
    func loadModel(config: ModelConfig, completion: @escaping (Result<Void, Error>) -> Void)
    func generate(request: GenerateRequest, completion: @escaping (Result<Void, Error>) -> Void)
    func generateChat(request: ChatRequest, completion: @escaping (Result<Void, Error>) -> Void)
    func getSupportedTemplates() -> [String]
    func stop(completion: @escaping (Result<Void, Error>) -> Void)
    func dispose(completion: @escaping (Result<Void, Error>) -> Void)
    func isModelLoaded() -> Bool
    func getContextInfo() -> ContextInfo
    func clearContext(completion: @escaping (Result<Void, Error>) -> Void)
    func setSystemPromptLength(length: Int64)
    func registerCustomTemplate(name: String, content: String)
    func unregisterCustomTemplate(name: String)
}

// MARK: - Channel registration

enum LlamaHostApiSetup {
    static func setUp(binaryMessenger: FlutterBinaryMessenger, api: LlamaHostApiProtocol?) {
        let codec = FlutterStandardMessageCodec.sharedInstance()

        func ch(_ name: String) -> FlutterBasicMessageChannel {
            FlutterBasicMessageChannel(name: name, binaryMessenger: binaryMessenger, codec: codec)
        }

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.loadModel").setMessageHandler(api == nil ? nil : { msg, reply in
            let args = msg as! [Any?]
            let config = ModelConfig.fromList(args[0] as! [Any?])
            api!.loadModel(config: config) { result in
                switch result {
                case .success: reply([nil])
                case .failure(let e): reply([["error", e.localizedDescription, nil]])
                }
            }
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.generate").setMessageHandler(api == nil ? nil : { msg, reply in
            let args = msg as! [Any?]
            let request = GenerateRequest.fromList(args[0] as! [Any?])
            api!.generate(request: request) { result in
                switch result {
                case .success: reply([nil])
                case .failure(let e): reply([["error", e.localizedDescription, nil]])
                }
            }
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.generateChat").setMessageHandler(api == nil ? nil : { msg, reply in
            let args = msg as! [Any?]
            let request = ChatRequest.fromList(args[0] as! [Any?])
            api!.generateChat(request: request) { result in
                switch result {
                case .success: reply([nil])
                case .failure(let e): reply([["error", e.localizedDescription, nil]])
                }
            }
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.getSupportedTemplates").setMessageHandler(api == nil ? nil : { _, reply in
            reply([api!.getSupportedTemplates()])
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.stop").setMessageHandler(api == nil ? nil : { _, reply in
            api!.stop { result in
                switch result {
                case .success: reply([nil])
                case .failure(let e): reply([["error", e.localizedDescription, nil]])
                }
            }
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.dispose").setMessageHandler(api == nil ? nil : { _, reply in
            api!.dispose { result in
                switch result {
                case .success: reply([nil])
                case .failure(let e): reply([["error", e.localizedDescription, nil]])
                }
            }
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.isModelLoaded").setMessageHandler(api == nil ? nil : { _, reply in
            reply([api!.isModelLoaded()])
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.getContextInfo").setMessageHandler(api == nil ? nil : { _, reply in
            let info = api!.getContextInfo()
            reply([info.toList()])
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.clearContext").setMessageHandler(api == nil ? nil : { _, reply in
            api!.clearContext { result in
                switch result {
                case .success: reply([nil])
                case .failure(let e): reply([["error", e.localizedDescription, nil]])
                }
            }
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.setSystemPromptLength").setMessageHandler(api == nil ? nil : { msg, reply in
            let args = msg as! [Any?]
            let length = args[0] is Int ? Int64(args[0] as! Int) : args[0] as! Int64
            api!.setSystemPromptLength(length: length)
            reply([nil])
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.registerCustomTemplate").setMessageHandler(api == nil ? nil : { msg, reply in
            let args = msg as! [Any?]
            api!.registerCustomTemplate(name: args[0] as! String, content: args[1] as! String)
            reply([nil])
        })

        ch("dev.flutter.pigeon.llama_flutter_android.LlamaHostApi.unregisterCustomTemplate").setMessageHandler(api == nil ? nil : { msg, reply in
            let args = msg as! [Any?]
            api!.unregisterCustomTemplate(name: args[0] as! String)
            reply([nil])
        })
    }
}

// MARK: - Flutter API (Swift calls Dart)

class LlamaFlutterApi {
    private let codec = FlutterStandardMessageCodec.sharedInstance()

    // Channels are cached — creating one per token call during inference causes excessive allocation
    private let tokenChannel: FlutterBasicMessageChannel
    private let doneChannel: FlutterBasicMessageChannel
    private let errorChannel: FlutterBasicMessageChannel
    private let progressChannel: FlutterBasicMessageChannel

    init(binaryMessenger: FlutterBinaryMessenger) {
        let base = "dev.flutter.pigeon.llama_flutter_android.LlamaFlutterApi"
        let codec = FlutterStandardMessageCodec.sharedInstance()
        tokenChannel    = FlutterBasicMessageChannel(name: "\(base).onToken",        binaryMessenger: binaryMessenger, codec: codec)
        doneChannel     = FlutterBasicMessageChannel(name: "\(base).onDone",         binaryMessenger: binaryMessenger, codec: codec)
        errorChannel    = FlutterBasicMessageChannel(name: "\(base).onError",        binaryMessenger: binaryMessenger, codec: codec)
        progressChannel = FlutterBasicMessageChannel(name: "\(base).onLoadProgress", binaryMessenger: binaryMessenger, codec: codec)
    }

    func onToken(_ token: String, completion: @escaping () -> Void) {
        tokenChannel.sendMessage([token]) { _ in completion() }
    }

    func onDone(completion: @escaping () -> Void) {
        doneChannel.sendMessage(nil) { _ in completion() }
    }

    func onError(_ error: String, completion: @escaping () -> Void) {
        errorChannel.sendMessage([error]) { _ in completion() }
    }

    func onLoadProgress(_ progress: Double, completion: @escaping () -> Void) {
        progressChannel.sendMessage([progress]) { _ in completion() }
    }
}
