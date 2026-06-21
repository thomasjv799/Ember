import SwiftUI

// ─────────────────────────────────────────────────────────────
// Section label — uppercase mono caption with an optional accent
// action on the trailing edge.
// ─────────────────────────────────────────────────────────────
struct SectionLabel: View {
    @Environment(\.theme) private var theme

    var title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    init(_ title: String, action: String? = nil, onAction: (() -> Void)? = nil) {
        self.title = title
        self.action = action
        self.onAction = onAction
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.mono(12.5))
                .tracking(0.08 * 12.5)
                .foregroundStyle(theme.text3)
            Spacer(minLength: 8)
            if let action {
                Button(action: { onAction?() }) {
                    Text(action)
                        .font(.ui(13, 600))
                        .foregroundStyle(theme.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 2)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }
}
