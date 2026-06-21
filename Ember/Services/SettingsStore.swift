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
    }
}
