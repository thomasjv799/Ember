import SwiftUI

// ─────────────────────────────────────────────────────────────
// Small looping animations from the design — each respects Reduce
// Motion by settling at the visible end-state.
// ─────────────────────────────────────────────────────────────

/// Live status dot — scale 1→0.55, opacity 1→0.3 (1.6s).
struct LiveDot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var color: Color
    var size: CGFloat = 6
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(pulsing ? 0.55 : 1)
            .opacity(pulsing ? 0.3 : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(Motion.pulseDot) { pulsing = true }
            }
    }
}

/// Streak flame — gentle flicker (scale + slight rotate, 2s).
struct FlickerFlame: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var size: CGFloat = 13
    @State private var flicker = false

    var body: some View {
        Icon(.flame, size: size, color: theme.accentColor, stroke: 2, fill: true)
            .scaleEffect(flicker ? 1.18 : 1.0)
            .rotationEffect(.degrees(flicker ? 3 : 0))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(Motion.flicker) { flicker = true }
            }
    }
}

/// Pulsing accent glow (for the active model / report icon, 2.6s).
private struct GlowPulse: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: theme.accentSoft, radius: pulsing ? 18 : 6)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(Motion.glowPulse) { pulsing = true }
            }
    }
}

extension View {
    func glowPulse() -> some View { modifier(GlowPulse()) }
}
