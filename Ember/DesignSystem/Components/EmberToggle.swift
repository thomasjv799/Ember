import SwiftUI

// ─────────────────────────────────────────────────────────────
// Toggle — custom switch matching the prototype (46×28, white knob,
// accent track when on).
// ─────────────────────────────────────────────────────────────
struct EmberToggle: View {
    @Environment(\.theme) private var theme
    @Binding var isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? theme.accentColor : Color.white.opacity(0.16))
            .frame(width: 46, height: 28)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
                    .padding(3)
            }
            .animation(Motion.toggle, value: isOn)
            .contentShape(Capsule())
            .onTapGesture { isOn.toggle() }
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(isOn ? "On" : "Off")
    }
}
