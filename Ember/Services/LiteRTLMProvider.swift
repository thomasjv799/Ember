// ─────────────────────────────────────────────────────────────
// LiteRTLMProvider — real on-device LLM via the LiteRT-LM Swift
// package, loading a `.litertlm` model. Compiled in only when the
// package is linked (#if canImport).
//
// Correctness notes:
//  • System instructions + health context go in ConversationConfig's
//    systemMessage; the user's text is sent as a PLAIN Message so the
//    model's own chat template is applied once (hand-rolling it caused
//    garbled / hallucinated output).
//  • The chat keeps a persistent Conversation for multi-turn memory.
//  • Backend (GPU/CPU), maxTokens, and sampler come from InferenceConfig.
// ─────────────────────────────────────────────────────────────
#if canImport(LiteRTLM)
import Foundation
import LiteRTLM
import OSLog

final class LiteRTLMProvider: LLMProviding {
    private static let log = Logger(subsystem: "com.ember.health", category: "Gemma")

    /// Console + Documents/gemma-debug.log (pullable via devicectl for diagnosis).
    private static func diag(_ message: String) {
        print("[Ember/Gemma] \(message)")
        log.info("\(message, privacy: .public)")
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let data = "\(Date()): \(message)\n".data(using: .utf8) else { return }
        let url = docs.appendingPathComponent("gemma-debug.log")
        if let handle = try? FileHandle(forWritingTo: url) {
            try? handle.seekToEnd(); try? handle.write(contentsOf: data); try? handle.close()
        } else {
            try? data.write(to: url)
        }
    }

    private let modelPath: String
    private let modelSizeBytes: Int64
    private var config: InferenceConfig
    private var engine: Engine?
    private var initTask: Task<Engine, Error>?
    private var chatConversation: Conversation?

    init(modelPath: String, config: InferenceConfig) {
        self.modelPath = modelPath
        self.config = config
        let attrs = try? FileManager.default.attributesOfItem(atPath: modelPath)
        self.modelSizeBytes = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? FileManager.default.removeItem(at: docs.appendingPathComponent("gemma-debug.log"))
        }
        Self.diag("provider init: model=\((modelPath as NSString).lastPathComponent) size=\(modelSizeBytes) backend=\(config.backend.rawValue) maxTokens=\(config.maxTokens)")
    }

    private var sizeGB: Double { Double(modelSizeBytes) / 1_073_741_824 }

    var modelStatus: ModelStatus {
        ModelStatus(
            name: "Gemma 3n",
            stateLabel: engine == nil ? "Ready" : "Active",
            detail: String(format: "LiteRT-LM · %@ · %.1f GB", config.backend.rawValue, sizeGB),
            isActive: true, usedGB: sizeGB, totalGB: 8, lastRun: "On-device"
        )
    }

    /// Live update of per-conversation params (temperature/topK/topP). Engine-level
    /// params (backend/maxTokens) are fixed at init; AppEnvironment makes a new
    /// provider when those change. Applies to new chats / after Clear.
    func updateSampler(_ newConfig: InferenceConfig) {
        config.temperature = newConfig.temperature
        config.topK = newConfig.topK
        config.topP = newConfig.topP
    }

    func resetChat() {
        chatConversation = nil
        Self.diag("chat reset")
    }

    // MARK: Engine lifecycle (chosen backend, with the other as init fallback)

    private func ready() async throws -> Engine {
        if let engine { return engine }
        if let initTask { return try await initTask.value }
        let path = modelPath
        let maxTok = config.maxTokens
        let primary: Backend = config.backend == .cpu ? .cpu() : .gpu
        let fallback: Backend = config.backend == .cpu ? .gpu : .cpu()
        let task = Task<Engine, Error> {
            do {
                return try await Self.makeEngine(path: path, backend: primary, maxTokens: maxTok)
            } catch {
                Self.diag("\(primary.rawValue) init failed: \(String(describing: error)) — trying \(fallback.rawValue)")
                return try await Self.makeEngine(path: path, backend: fallback, maxTokens: maxTok)
            }
        }
        initTask = task
        do {
            let e = try await task.value
            engine = e
            return e
        } catch {
            initTask = nil
            throw error
        }
    }

    private static func makeEngine(path: String, backend: Backend, maxTokens: Int) async throws -> Engine {
        diag("Initializing LiteRT-LM backend=\(backend.rawValue) maxTokens=\(maxTokens) model=\((path as NSString).lastPathComponent)")
        let cfg = try EngineConfig(modelPath: path, backend: backend, maxNumTokens: maxTokens, cacheDir: NSTemporaryDirectory())
        let engine = Engine(engineConfig: cfg)
        try await engine.initialize()
        diag("engine READY backend=\(backend.rawValue)")
        return engine
    }

    private func samplerConfig() -> SamplerConfig? {
        try? SamplerConfig(topK: config.topK, topP: Float(config.topP), temperature: Float(config.temperature))
    }

    private func systemMessage(context: String) -> Message {
        Message("You are Ember, a private on-device health assistant. Answer in plain language, concise, specific, and encouraging. Use only the user's data below — never invent numbers.\n\nUser's health data:\n\(context)")
    }

    private static func text(from message: Message) -> String {
        let t = message.toString
        return t.isEmpty ? message.channels.values.joined() : t
    }

    // MARK: LLMProviding

    func dailySuggestion(context: String) async -> String {
        await oneShot(context: context, instruction: "In 2-3 sentences, give one concrete suggestion for today.")
    }

    func weeklySummary(context: String) async -> String {
        await oneShot(context: context, instruction: "Summarize my week in 3-4 sentences (steps, resting heart rate, sleep), ending with one encouraging insight.")
    }

    func insights(context: String) async -> [String] {
        let text = await oneShot(context: context, instruction: "List 4 short, specific insights about my data, one per line, no numbering or bullets.")
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "-•*0123456789. \t")) }
            .filter { !$0.isEmpty }
        return lines.isEmpty ? [text] : lines
    }

    /// One-shot generation: a fresh conversation each call (no carry-over).
    private func oneShot(context: String, instruction: String) async -> String {
        Self.diag("oneShot requested")
        do {
            let engine = try await ready()
            let convo = try await engine.createConversation(
                with: ConversationConfig(systemMessage: systemMessage(context: context), samplerConfig: samplerConfig()))
            let response = try await convo.sendMessage(Message(instruction))
            let out = Self.text(from: response)
            Self.diag("oneShot produced \(out.count) chars")
            return out.isEmpty ? "The model returned no text." : out
        } catch {
            Self.diag("oneShot error: \(String(describing: error))")
            return "On-device model error: \(String(describing: error))"
        }
    }

    /// Multi-turn chat over a persistent conversation (remembers prior turns).
    func reply(to prompt: String, context: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                Self.diag("reply requested")
                do {
                    let convo = try await self.chatReady(context: context)
                    var produced = false
                    var chunks = 0
                    for try await chunk in convo.sendMessageStream(Message(prompt)) {
                        if Task.isCancelled { break }
                        chunks += 1
                        let t = Self.text(from: chunk)
                        if !t.isEmpty { produced = true; continuation.yield(t) }
                    }
                    Self.diag("chat finished: chunks=\(chunks) producedText=\(produced)")
                    if !produced {
                        continuation.yield("The model returned no text — try tapping Clear to reset the conversation.")
                    }
                } catch {
                    Self.diag("chat error: \(String(describing: error))")
                    continuation.yield("On-device model error: \(String(describing: error))")
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func chatReady(context: String) async throws -> Conversation {
        if let chatConversation { return chatConversation }
        let engine = try await ready()
        let convo = try await engine.createConversation(
            with: ConversationConfig(systemMessage: systemMessage(context: context), samplerConfig: samplerConfig()))
        chatConversation = convo
        return convo
    }
}
#endif
