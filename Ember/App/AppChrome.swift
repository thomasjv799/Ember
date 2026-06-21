import SwiftUI

// ─────────────────────────────────────────────────────────────
// Floating privacy banner — fixed below the status bar on the
// main tabs (not Ask, not Detail). Reassures: data stays local.
// ─────────────────────────────────────────────────────────────
private struct PrivacyBannerModifier: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(AppEnvironment.self) private var env

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            if env.settings.privacyBanner {
                HStack(spacing: 7) {
                    Icon(.shield, size: 13, color: theme.accentColor, stroke: 1.9)
                    Text("On-device · your data stays on this iPhone")
                        .font(.mono(11.5))
                        .foregroundStyle(theme.accentColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(theme.accentLine, lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 10)
                .background(theme.bg)
            }
        }
    }
}

extension View {
    /// Adds the fixed on-device privacy banner above the content.
    func privacyBanner() -> some View { modifier(PrivacyBannerModifier()) }
}

// ─────────────────────────────────────────────────────────────
// A standard scrollable screen body: vertical scroll, screen
// horizontal padding, bottom space for the tab bar, screen-enter
// motion. Used by Today / Weekly / Insights / Settings.
// ─────────────────────────────────────────────────────────────
struct ScreenScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DS.sectionGap) {
                content()
            }
            .padding(.top, 8)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .screenEnter()
    }
}
