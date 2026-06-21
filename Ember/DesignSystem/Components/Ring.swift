import SwiftUI

// ─────────────────────────────────────────────────────────────
// Progress ring — track + value arc (gradient or solid), with
// optional centered content. Fills with the 1s stroke animation.
// ─────────────────────────────────────────────────────────────
struct Ring<Center: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var size: CGFloat = 120
    var stroke: CGFloat = 12
    var value: Double
    var maxValue: Double = 100
    var gradient: [Color]? = nil
    var solid: Color? = nil
    var track: Color = Color.white.opacity(0.08)
    @ViewBuilder var center: () -> Center

    @State private var animated: CGFloat = 0

    private var pct: CGFloat { max(0, min(1, CGFloat(value / max(maxValue, 0.0001)))) }

    private var fillStyle: AnyShapeStyle {
        if let gradient {
            return AnyShapeStyle(
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
        return AnyShapeStyle(solid ?? Color.accentColor)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, style: StrokeStyle(lineWidth: stroke))
            Circle()
                .trim(from: 0, to: animated)
                .stroke(fillStyle, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
            center()
        }
        .frame(width: size, height: size)
        .onAppear { set(pct) }
        .onChange(of: pct) { _, new in set(new) }
    }

    private func set(_ target: CGFloat) {
        if reduceMotion {
            animated = target
        } else {
            withAnimation(Motion.ringFill) { animated = target }
        }
    }
}

extension Ring where Center == EmptyView {
    init(size: CGFloat = 120, stroke: CGFloat = 12, value: Double, maxValue: Double = 100,
         gradient: [Color]? = nil, solid: Color? = nil, track: Color = Color.white.opacity(0.08)) {
        self.init(size: size, stroke: stroke, value: value, maxValue: maxValue,
                  gradient: gradient, solid: solid, track: track) { EmptyView() }
    }
}
