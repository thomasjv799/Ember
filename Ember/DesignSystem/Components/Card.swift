import SwiftUI

// ─────────────────────────────────────────────────────────────
// Card chrome — surface fill, hairline border, rounded corners,
// and either the elevated shadow or the accent glow.
// Apply to any container (used directly for decorated cards that
// build their own ZStack, e.g. the weekly hero / report banner).
// ─────────────────────────────────────────────────────────────
struct CardChrome: ViewModifier {
    @Environment(\.theme) private var theme
    var glow: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
        content
            .background(theme.surface)
            .clipShape(shape)
            .overlay(shape.strokeBorder(glow ? theme.accentSoft : theme.cardBorder, lineWidth: 1))
            .modifier(CardShadow(glow: glow))
    }
}

private struct CardShadow: ViewModifier {
    @Environment(\.theme) private var theme
    var glow: Bool

    func body(content: Content) -> some View {
        if glow {
            content.shadow(color: theme.accentSoft, radius: 15, x: 0, y: 8)
        } else if theme.hasCardShadow {
            content.shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 4)
        } else {
            content
        }
    }
}

extension View {
    func cardChrome(glow: Bool = false) -> some View { modifier(CardChrome(glow: glow)) }
}

// ─────────────────────────────────────────────────────────────
// Card — standard padded container. Fills available width.
// ─────────────────────────────────────────────────────────────
struct Card<Content: View>: View {
    var padding: EdgeInsets
    var glow: Bool
    @ViewBuilder var content: () -> Content

    init(padding: EdgeInsets, glow: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.glow = glow
        self.content = content
    }

    init(pad: CGFloat = 16, glow: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.init(padding: EdgeInsets(top: pad, leading: pad, bottom: pad, trailing: pad), glow: glow, content: content)
    }

    init(padV: CGFloat, padH: CGFloat, glow: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.init(padding: EdgeInsets(top: padV, leading: padH, bottom: padV, trailing: padH), glow: glow, content: content)
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .cardChrome(glow: glow)
    }
}
