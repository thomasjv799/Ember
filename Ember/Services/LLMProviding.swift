import Foundation

// ─────────────────────────────────────────────────────────────
// LLMProviding — the on-device assistant behind a protocol. The
// generative calls take a `context` string built from the user's
// real HealthKit data so output is grounded, not generic.
//
// On device the real provider is LiteRTLMProvider (Gemma via
// LiteRT-LM); the mock is used only in the simulator for UI work.
// ─────────────────────────────────────────────────────────────
protocol LLMProviding {
    var modelStatus: ModelStatus { get }
    var suggestedPrompts: [String] { get }
    func greeting(for name: String) -> String

    func dailySuggestion(context: String) async -> String
    func weeklySummary(context: String) async -> String
    func insights(context: String) async -> [String]
    func reply(to prompt: String, context: String) -> AsyncStream<String>

    /// Reset multi-turn chat memory (new conversation on next reply).
    func resetChat()
    /// Apply live sampler params (temperature/topK/topP) to future conversations.
    func updateSampler(_ config: InferenceConfig)
}

extension LLMProviding {
    func resetChat() {}
    func updateSampler(_ config: InferenceConfig) {}

    func greeting(for name: String) -> String {
        "Hi \(name) — I'm running locally on this iPhone. Ask me anything about your health data. Nothing you say leaves the device."
    }
    var suggestedPrompts: [String] {
        [
            "Why was my sleep low this week?",
            "How do I hit my step goal today?",
            "Is my resting heart rate healthy?",
        ]
    }
}

// ─────────────────────────────────────────────────────────────
// MockGemmaProvider — canned, keyword-routed replies with simulated
// streaming. Simulator/dev only (real device requires a model).
// ─────────────────────────────────────────────────────────────
struct MockGemmaProvider: LLMProviding {
    var modelStatus: ModelStatus { MockData.modelStatus }

    func dailySuggestion(context: String) async -> String {
        MockData.insights[0].detail
    }

    func weeklySummary(context: String) async -> String {
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        return MockData.week.summary
    }

    func insights(context: String) async -> [String] {
        MockData.insights.map { $0.headline }
    }

    func reply(to prompt: String, context: String) -> AsyncStream<String> {
        let full = Self.cannedReply(to: prompt)
        return AsyncStream { continuation in
            let task = Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                let words = full.split(separator: " ", omittingEmptySubsequences: false)
                for (i, word) in words.enumerated() {
                    if Task.isCancelled { break }
                    continuation.yield(String(word) + (i < words.count - 1 ? " " : ""))
                    try? await Task.sleep(nanoseconds: 26_000_000)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func cannedReply(to text: String) -> String {
        let q = text.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { q.contains($0) } }
        if has(["sleep", "rest", "tired", "bed"]) {
            return "Your sleep averaged 6h 48m this week — about 42 min under your 7h 30m target. Try a consistent 10:45 PM wind-down."
        }
        if has(["step", "walk", "move", "active", "goal"]) {
            return "You're at 7,420 of 10,000 steps with about 5 active hours left. A brisk 22-minute walk closes the gap."
        }
        if has(["heart", "hr", "bpm", "cardio", "pulse"]) {
            return "Your resting heart rate is 57 bpm — a 6-month low and down 3 bpm in two weeks. That's a healthy range."
        }
        return "Based on your last 7 days: activity is up 9%, resting heart rate is down 3 bpm, and sleep is your one weak spot at 6h 48m."
    }
}
