import SwiftUI

// ─────────────────────────────────────────────────────────────
// Glyphs — the prototype's inline SVG line icons, mapped to the
// closest SF Symbols (per the handoff's recommended mapping).
// ─────────────────────────────────────────────────────────────
enum Glyph {
    case home, weekly, spark, gear, sliders
    case chevron, chevronL, arrowUp, arrowRight
    case steps, heart, moon, flame
    case shield, chip, check, apple, bell, lock, refresh, plus, target, info, leaf, chat, mic

    func symbol(filled: Bool) -> String {
        switch self {
        case .home:       return filled ? "house.fill" : "house"
        case .weekly:     return "calendar"
        case .spark:      return "sparkles"
        case .gear:       return "gearshape"
        case .sliders:    return "slider.horizontal.3"
        case .chevron:    return "chevron.right"
        case .chevronL:   return "chevron.left"
        case .arrowUp:    return "arrow.up"
        case .arrowRight: return "arrow.right"
        case .steps:      return "figure.walk"
        case .heart:      return filled ? "heart.fill" : "heart"
        case .moon:       return filled ? "moon.fill" : "moon"
        case .flame:      return filled ? "flame.fill" : "flame"
        case .shield:     return filled ? "shield.fill" : "shield"
        case .chip:       return "cpu"
        case .check:      return "checkmark"
        case .apple:      return "applelogo"
        case .bell:       return filled ? "bell.fill" : "bell"
        case .lock:       return filled ? "lock.fill" : "lock"
        case .refresh:    return "arrow.clockwise"
        case .plus:       return "plus"
        case .target:     return "target"
        case .info:       return "info.circle"
        case .leaf:       return "leaf"
        case .chat:       return "message"
        case .mic:        return filled ? "mic.fill" : "mic"
        }
    }
}

// ─────────────────────────────────────────────────────────────
// Icon — renders a glyph at a size/color, approximating the
// prototype's SVG stroke-width via SF Symbol weight.
// ─────────────────────────────────────────────────────────────
struct Icon: View {
    let glyph: Glyph
    var size: CGFloat = 20
    var color: Color = .primary
    var stroke: CGFloat = 2
    var fill: Bool = false

    init(_ glyph: Glyph, size: CGFloat = 20, color: Color = .primary, stroke: CGFloat = 2, fill: Bool = false) {
        self.glyph = glyph
        self.size = size
        self.color = color
        self.stroke = stroke
        self.fill = fill
    }

    private var weight: Font.Weight {
        switch stroke {
        case ..<1.9:  return .regular
        case ..<2.2:  return .medium
        case ..<2.5:  return .semibold
        default:      return .bold
        }
    }

    var body: some View {
        Image(systemName: glyph.symbol(filled: fill))
            .font(.system(size: size, weight: weight))
            .foregroundStyle(color)
    }
}
