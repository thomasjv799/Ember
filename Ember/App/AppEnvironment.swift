import SwiftUI

// ─────────────────────────────────────────────────────────────
// AppEnvironment — dependency container. Holds settings, the
// service providers, and the model manager. The LLM is resolved at
// runtime: nil until a `.litertlm` model is installed (AI surfaces
// gate on `hasIntelligence`); the simulator uses a mock for UI work.
// ─────────────────────────────────────────────────────────────
@MainActor
@Observable
final class AppEnvironment {
    let settings: SettingsStore
    let health: HealthDataProviding
    let speech: SpeechTranscribing
    let modelManager: ModelManager

    @ObservationIgnored private var cachedLLM: LLMProviding?
    @ObservationIgnored private var cachedModelPath: String?
    @ObservationIgnored private var cachedEngineKey: String?

    init(settings: SettingsStore, health: HealthDataProviding,
         speech: SpeechTranscribing, modelManager: ModelManager) {
        self.settings = settings
        self.health = health
        self.speech = speech
        self.modelManager = modelManager
    }

    /// True when the assistant can run (observes model status so the UI updates
    /// the moment a download/import completes).
    var hasIntelligence: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        if case .installed = modelManager.status { return true }
        return false
        #endif
    }

    /// The on-device LLM when available, else nil. Caches the engine per model path.
    func intelligence() -> LLMProviding? {
        #if targetEnvironment(simulator)
        if cachedLLM == nil { cachedLLM = MockGemmaProvider() }
        return cachedLLM
        #elseif canImport(LiteRTLM)
        guard let path = GemmaModel.installedModelPath() else {
            cachedLLM = nil; cachedModelPath = nil; cachedEngineKey = nil; return nil
        }
        let config = settings.inferenceConfig
        // Reuse the engine while model + engine-level params (backend/maxTokens) are
        // unchanged; just push live sampler updates. Otherwise rebuild.
        if cachedModelPath == path, cachedEngineKey == config.engineKey, let cached = cachedLLM {
            cached.updateSampler(config)
            return cached
        }
        let provider = LiteRTLMProvider(modelPath: path, config: config)
        cachedLLM = provider
        cachedModelPath = path
        cachedEngineKey = config.engineKey
        return provider
        #else
        return nil
        #endif
    }

    static func live() -> AppEnvironment {
        let settings = SettingsStore()
        let modelManager = ModelManager()
        #if targetEnvironment(simulator)
        return AppEnvironment(settings: settings, health: MockHealthProvider(),
                              speech: MockSpeechProvider(), modelManager: modelManager)
        #else
        var health: HealthDataProviding = MockHealthProvider()
        #if canImport(HealthKit)
        health = HealthKitProvider()
        #endif

        var speech: SpeechTranscribing = MockSpeechProvider()
        #if canImport(Speech) && canImport(AVFoundation)
        speech = SpeechProvider()
        #endif

        return AppEnvironment(settings: settings, health: health,
                              speech: speech, modelManager: modelManager)
        #endif
    }

    static func mock() -> AppEnvironment {
        AppEnvironment(settings: SettingsStore(ud: UserDefaults(suiteName: "preview") ?? .standard),
                       health: MockHealthProvider(), speech: MockSpeechProvider(),
                       modelManager: ModelManager())
    }
}
