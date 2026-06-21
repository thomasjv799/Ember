import SwiftUI

// ─────────────────────────────────────────────────────────────
// SettingsStore — observable, UserDefaults-backed app preferences.
// Drives theming (accent / card style / radius), the privacy
// banner, onboarding gate, and toggles surfaced in Settings.
// ─────────────────────────────────────────────────────────────
@Observable
final class SettingsStore {

    var onboarded: Bool { didSet { ud.set(onboarded, forKey: Keys.onboarded) } }
    var accent: AccentTheme { didSet { ud.set(accent.rawValue, forKey: Keys.accent) } }
    var cardStyle: CardStyle { didSet { ud.set(cardStyle.rawValue, forKey: Keys.cardStyle) } }
    var cornerRadius: Double { didSet { ud.set(cornerRadius, forKey: Keys.radius) } }
    var privacyBanner: Bool { didSet { ud.set(privacyBanner, forKey: Keys.privacyBanner) } }
    var dailySuggestions: Bool { didSet { ud.set(dailySuggestions, forKey: Keys.dailySuggestions) } }
    var processOnDeviceOnly: Bool { didSet { ud.set(processOnDeviceOnly, forKey: Keys.processOnDeviceOnly) } }
    var userName: String { didSet { ud.set(userName, forKey: Keys.userName) } }
    var llmBackend: LLMBackend { didSet { ud.set(llmBackend.rawValue, forKey: Keys.llmBackend) } }
    var llmTemperature: Double { didSet { ud.set(llmTemperature, forKey: Keys.llmTemperature) } }
    var llmMaxTokens: Int { didSet { ud.set(llmMaxTokens, forKey: Keys.llmMaxTokens) } }

    @ObservationIgnored private let ud: UserDefaults

    init(ud: UserDefaults = .standard) {
        self.ud = ud
        onboarded = ud.bool(forKey: Keys.onboarded)
        accent = AccentTheme(rawValue: ud.string(forKey: Keys.accent) ?? "") ?? .rouge
        cardStyle = CardStyle(rawValue: ud.string(forKey: Keys.cardStyle) ?? "") ?? .elevated
        cornerRadius = (ud.object(forKey: Keys.radius) as? Double) ?? 22
        privacyBanner = (ud.object(forKey: Keys.privacyBanner) as? Bool) ?? true
        dailySuggestions = (ud.object(forKey: Keys.dailySuggestions) as? Bool) ?? true
        processOnDeviceOnly = (ud.object(forKey: Keys.processOnDeviceOnly) as? Bool) ?? true
        userName = ud.string(forKey: Keys.userName) ?? ""
        llmBackend = LLMBackend(rawValue: ud.string(forKey: Keys.llmBackend) ?? "") ?? .gpu
        llmTemperature = (ud.object(forKey: Keys.llmTemperature) as? Double) ?? 0.4
        llmMaxTokens = (ud.object(forKey: Keys.llmMaxTokens) as? Int) ?? 1024
    }

    /// The resolved theme derived from current preferences.
    var theme: Theme {
        Theme(accent: accent, cardStyle: cardStyle, radius: CGFloat(cornerRadius))
    }

    /// The user's name, falling back to the demo identity if not set.
    var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? MockData.userName : trimmed
    }

    /// Up to two initials for the profile avatar.
    var initials: String {
        let parts = displayName.split(separator: " ").compactMap(\.first).prefix(2)
        let result = String(parts).uppercased()
        return result.isEmpty ? "?" : result
    }

    /// Inference parameters for the on-device model.
    var inferenceConfig: InferenceConfig {
        InferenceConfig(backend: llmBackend, temperature: llmTemperature, maxTokens: llmMaxTokens)
    }

    func completeOnboarding() { onboarded = true }
    func replayOnboarding() { onboarded = false }

    private enum Keys {
        static let onboarded = "ember.onboarded"
        static let accent = "ember.accent"
        static let cardStyle = "ember.cardStyle"
        static let radius = "ember.cornerRadius"
        static let privacyBanner = "ember.privacyBanner"
        static let dailySuggestions = "ember.dailySuggestions"
        static let processOnDeviceOnly = "ember.processOnDeviceOnly"
        static let userName = "ember.userName"
        static let llmBackend = "ember.llmBackend"
        static let llmTemperature = "ember.llmTemperature"
        static let llmMaxTokens = "ember.llmMaxTokens"
    }
}
