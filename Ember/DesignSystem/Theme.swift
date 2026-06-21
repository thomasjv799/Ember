import SwiftUI

// ─────────────────────────────────────────────────────────────
// Color from hex — the design spec is specified in hex/rgba.
// ─────────────────────────────────────────────────────────────
extension Color {
    /// `Color(hex: 0xfb3b5a)` — sRGB, optional alpha.
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// ─────────────────────────────────────────────────────────────
// Typography — UI = SF Pro (system), mono = SF Mono.
// The design uses CSS numeric weights; map them to SwiftUI.
// ─────────────────────────────────────────────────────────────
extension Font.Weight {
    /// Maps a CSS numeric font-weight from the design spec to the nearest SwiftUI weight.
    init(css: Int) {
        switch css {
        case ..<450:  self = .regular
        case ..<560:  self = .medium      // 520, 540
        case ..<680:  self = .semibold    // 600, 650
        case ..<745:  self = .bold        // 680, 700, 720, 730, 740
        default:      self = .heavy       // 760+
        }
    }
}

extension Font {
    /// System (SF Pro) font at a CSS-style numeric weight.
    static func ui(_ size: CGFloat, _ css: Int = 400) -> Font {
        .system(size: size, weight: Font.Weight(css: css))
    }
    /// Monospaced (SF Mono) font — used for labels, units, timestamps, on-device tags.
    static func mono(_ size: CGFloat, _ css: Int = 400) -> Font {
        .system(size: size, weight: Font.Weight(css: css), design: .monospaced)
    }
}

// ─────────────────────────────────────────────────────────────
// Spacing / layout tokens
// ─────────────────────────────────────────────────────────────
enum DS {
    static let screenH: CGFloat = 16        // screen horizontal padding
    static let headerH: CGFloat = 20        // header side padding
    static let sectionGap: CGFloat = 16     // gap between sections
    static let tabBarSpace: CGFloat = 96    // bottom inset to clear the tab bar
}

// ─────────────────────────────────────────────────────────────
// Card style (user-switchable)
// ─────────────────────────────────────────────────────────────
enum CardStyle: String, CaseIterable, Identifiable, Codable {
    case elevated = "Elevated"
    case outlined = "Outlined"
    var id: String { rawValue }
}

// ─────────────────────────────────────────────────────────────
// Theme — resolved design tokens, injected via the environment.
// Derived from user prefs (accent / cardStyle / radius).
// ─────────────────────────────────────────────────────────────
struct Theme {
    var accent: AccentTheme = .rouge
    var cardStyle: CardStyle = .elevated
    var radius: CGFloat = 22

    // Accent-derived
    var accentColor: Color { accent.accent }
    var accent2Color: Color { accent.accent2 }
    var accentSoft: Color { accent.soft }
    var accentLine: Color { accent.line }

    // Base palette (warm near-black dark theme)
    var bg: Color { Color(hex: 0x0C0B0A) }
    var bg2: Color { Color(hex: 0x141210) }
    var surface: Color { cardStyle == .elevated ? Color(hex: 0x1A1714) : Color.white.opacity(0.025) }
    var textColor: Color { Color(hex: 0xF4F0EA) }
    var text2: Color { Color(hex: 0xF4F0EA, alpha: 0.62) }
    var text3: Color { Color(hex: 0xF4F0EA, alpha: 0.38) }
    var good: Color { Color(hex: 0x5EC98A) }
    var goodSoft: Color { Color(hex: 0x5EC98A, alpha: 0.14) }
    var hair: Color { Color.white.opacity(0.07) }
    var hairStrong: Color { Color.white.opacity(0.14) }

    // Card chrome
    var cardBorder: Color { cardStyle == .elevated ? Color.white.opacity(0.07) : Color.white.opacity(0.10) }
    var hasCardShadow: Bool { cardStyle == .elevated }

    // Fixed metric colors (not accent-switchable)
    static let heart = Color(hex: 0xE8596A)
    static let sleep = Color(hex: 0x8A8FE6)
    /// Dark text used on top of accent-filled surfaces.
    static let darkOnAccent = Color(hex: 0x1A1410)
}

// ─────────────────────────────────────────────────────────────
// Environment plumbing
// ─────────────────────────────────────────────────────────────
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
