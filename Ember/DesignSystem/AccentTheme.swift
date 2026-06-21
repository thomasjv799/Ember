import SwiftUI

// ─────────────────────────────────────────────────────────────
// Accent themes — user-switchable. Rouge is the default.
// Values mirror the design handoff's ACCENTS table exactly.
// ─────────────────────────────────────────────────────────────
enum AccentTheme: String, CaseIterable, Identifiable, Codable {
    case rouge = "Rouge"
    case amber = "Amber"
    case iris  = "Iris"
    case mint  = "Mint"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .rouge: return Color(hex: 0xFB3B5A)
        case .amber: return Color(hex: 0xFF6A3D)
        case .iris:  return Color(hex: 0xA85CFF)
        case .mint:  return Color(hex: 0x10E08A)
        }
    }

    var accent2: Color {
        switch self {
        case .rouge: return Color(hex: 0xFF8A8F)
        case .amber: return Color(hex: 0xFFB13C)
        case .iris:  return Color(hex: 0xD98AFF)
        case .mint:  return Color(hex: 0x67F0C4)
        }
    }

    /// Soft fill (~0.20–0.22 alpha) — chip / glow backgrounds.
    var soft: Color {
        switch self {
        case .mint: return accent.opacity(0.20)
        default:    return accent.opacity(0.22)
        }
    }

    /// Hairline border on soft chips (~0.45–0.46 alpha).
    var line: Color {
        switch self {
        case .amber, .mint: return accent.opacity(0.45)
        default:            return accent.opacity(0.46)
        }
    }
}
