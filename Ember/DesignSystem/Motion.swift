import SwiftUI

// ─────────────────────────────────────────────────────────────
// Motion — the design's durations / easing, in one place.
// Easing cubic-bezier(.4, 0, .2, 1) is the standard curve.
// All looping animations must be gated on Reduce Motion by the
// caller; base states are always the visible end-state.
// ─────────────────────────────────────────────────────────────
enum Motion {
    /// cubic-bezier(.4, 0, .2, 1)
    static func standard(_ duration: Double) -> Animation {
        .timingCurve(0.4, 0, 0.2, 1, duration: duration)
    }

    static let ringFill    = standard(1.0)   // stroke-dashoffset fill
    static let barGrow     = standard(0.7)    // bars grow in
    static let screenEnter = standard(0.35)   // screen translateY(8→0)
    static let toggle      = Animation.easeInOut(duration: 0.2)

    // Looping
    static let pulseDot  = Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true)
    static let glowPulse = Animation.easeInOut(duration: 2.6).repeatForever(autoreverses: true)
    static let flicker   = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    static let spin      = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)

    static func waveBar(delay: Double) -> Animation {
        .easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(delay)
    }
    static func typeDot(delay: Double) -> Animation {
        .easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(delay)
    }
}

// ─────────────────────────────────────────────────────────────
// Screen-enter: translateY(8 → 0) over .35s, no opacity fade so
// content is always visible (and stays visible under Reduce Motion).
// ─────────────────────────────────────────────────────────────
private struct ScreenEnter: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .offset(y: (appeared || reduceMotion) ? 0 : 8)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(Motion.screenEnter) { appeared = true }
            }
    }
}

extension View {
    /// Applies the design's screen-entry motion (respects Reduce Motion).
    func screenEnter() -> some View { modifier(ScreenEnter()) }
}
