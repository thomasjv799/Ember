import Foundation

// ─────────────────────────────────────────────────────────────
// On-device inference configuration (user-tunable in Settings).
// ─────────────────────────────────────────────────────────────
enum LLMBackend: String, CaseIterable, Identifiable, Codable {
    case gpu = "GPU"   // Metal — required by the gemma-4 .litertlm models
    case cpu = "CPU"
    var id: String { rawValue }
}

struct InferenceConfig: Equatable {
    var backend: LLMBackend = .gpu
    var temperature: Double = 0.4
    var maxTokens: Int = 1024
    var topK: Int = 40
    var topP: Double = 0.95

    /// Identity used to cache the engine — only engine-level params (rebuilding the
    /// engine is needed when these change; temperature/topK/topP are per-conversation).
    var engineKey: String { "\(backend.rawValue)|\(maxTokens)" }
}
