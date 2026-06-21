import Foundation

// ─────────────────────────────────────────────────────────────
// LiteRTLMProvider — real on-device LLM via the LiteRT-LM Swift
// package (google-ai-edge/LiteRT-LM), loading a `.litertlm` model.
// Compiled in only when the package is linked (#if canImport).
//
// API (LiteRT-LM v0.13.x):
//   let config = try EngineConfig(modelPath:, backend: .gpu, cacheDir:)
//   let engine = Engine(engineConfig: config); try await engine.initialize()
//   let convo  = try await engine.createConversation()
//   try await convo.sendMessage(Message(text)).toString
//   for try await chunk in convo.sendMessageStream(Message(text)) { chunk.toString }
// ─────────────────────────────────────────────────────────────
#if canImport(LiteRTLM)
import LiteRTLM

final class LiteRTLMProvider: LLMProviding {
    private let modelPath: String
    private let modelSizeBytes: Int64

    // Engine is initialized lazily on first use (initialize() is async),
    // and the in-flight init is shared so concurrent callers don't double-load.
    private var engine: Engine?
    private var initTask: Task<Engine, Error>?

    init(modelPath: String) {
        self.modelPath = modelPath
        let attrs = try? FileManager.default.attributesOfItem(atPath: modelPath)
        self.modelSizeBytes = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
    }

    private var sizeGB: Double { Double(modelSizeBytes) / 1_073_741_824 }

    var modelStatus: ModelStatus {
        ModelStatus(
            name: "Gemma 3n",
            stateLabel: engine == nil ? "Ready" : "Active",
            detail: String(format: "LiteRT-LM · on-device · %.1f GB", sizeGB),
            isActive: true,
            usedGB: sizeGB,
            totalGB: 8,
            lastRun: "On-device"
        )
    }

    // MARK: Engine lifecycle

    private func ready() async throws -> Engine {
        if let engine { return engine }
        if let initTask { return try await initTask.value }
        let modelPath = self.modelPath
        let task = Task<Engine, Error> {
            let config = try EngineConfig(
                modelPath: modelPath,
                backend: .gpu,
                cacheDir: NSTemporaryDirectory()
            )
            let engine = Engine(engineConfig: config)
            try await engine.initialize()
            return engine
        }
        initTask = task
        do {
            let engine = try await task.value
            self.engine = engine
            return engine
        } catch {
            initTask = nil   // allow retry on failure
            throw error
        }
    }

    // MARK: LLMProviding

    func dailySuggestion(context: String) async -> String {
        (try? await generate(Prompts.dailySuggestion(context))) ?? "Couldn't generate a suggestion right now."
    }

    func weeklySummary(context: String) async -> String {
        (try? await generate(Prompts.weeklySummary(context))) ?? "Couldn't generate a summary right now."
    }

    func insights(context: String) async -> [String] {
        guard let text = try? await generate(Prompts.insights(context)) else { return [] }
        return text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "-•*0123456789. \t")) }
            .filter { !$0.isEmpty }
    }

    func reply(to prompt: String, context: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                do {
                    let engine = try await ready()
                    let conversation = try await engine.createConversation()
                    for try await chunk in conversation.sendMessageStream(Message(Prompts.chat(prompt, context: context))) {
                        if Task.isCancelled { break }
                        continuation.yield(chunk.toString)
                    }
                } catch {
                    continuation.yield("On-device model error: \(error.localizedDescription)")
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func generate(_ prompt: String) async throws -> String {
        let engine = try await ready()
        let conversation = try await engine.createConversation()
        return try await conversation.sendMessage(Message(prompt)).toString
    }
}

// Prompt templates — the user's real HealthKit numbers are injected as `context`.
private enum Prompts {
    static let system = "You are Ember, a private on-device health assistant. Be concise, specific, and encouraging. Use only the user's data below; never invent numbers."
    static func dailySuggestion(_ ctx: String) -> String {
        "\(system)\n\nUser's health data:\n\(ctx)\n\nIn 2-3 sentences, give one concrete suggestion for today."
    }
    static func weeklySummary(_ ctx: String) -> String {
        "\(system)\n\nUser's health data:\n\(ctx)\n\nSummarize the user's week in 3-4 sentences (steps, resting heart rate, sleep), ending with one encouraging insight."
    }
    static func insights(_ ctx: String) -> String {
        "\(system)\n\nUser's health data:\n\(ctx)\n\nList 4 short, specific insights about this data, one per line, no numbering."
    }
    static func chat(_ q: String, context ctx: String) -> String {
        "\(system)\n\nUser's health data:\n\(ctx)\n\nUser: \(q)\nEmber:"
    }
}
#endif
