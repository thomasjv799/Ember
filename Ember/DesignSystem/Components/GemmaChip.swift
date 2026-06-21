import SwiftUI

// ─────────────────────────────────────────────────────────────
// "Generated on-device" chip — privacy surfaced as a feature.
// ─────────────────────────────────────────────────────────────
struct GemmaChip: View {
    @Environment(\.theme) private var theme

    var small: Bool = false
    var label: String = "Generated on-device"

    var body: some View {
        HStack(spacing: 6) {
            Icon(.chip, size: small ? 12 : 13, color: theme.accentColor, stroke: 1.8)
            Text(label)
                .font(.mono(small ? 10.5 : 11.5, 600))
                .tracking(0.02 * (small ? 10.5 : 11.5))
                .foregroundStyle(theme.accentColor)
        }
        .padding(.horizontal, small ? 8 : 10)
        .padding(.vertical, small ? 3 : 5)
        .background(theme.accentSoft, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.accentLine, lineWidth: 1))
        .fixedSize()
    }
}
