import SwiftUI

// ─────────────────────────────────────────────────────────────
// Ember logo — rounded-square accent tile containing a ring glyph.
// Matches onboarding.jsx `Logo`.
// ─────────────────────────────────────────────────────────────
struct EmberLogo: View {
    @Environment(\.theme) private var theme
    var size: CGFloat = 40

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(theme.accentColor)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .strokeBorder(Theme.darkOnAccent, lineWidth: size * 0.085)
                    .frame(width: size * 0.42, height: size * 0.42)
            }
            .shadow(color: theme.accentSoft, radius: 12, x: 0, y: 8)
    }
}
