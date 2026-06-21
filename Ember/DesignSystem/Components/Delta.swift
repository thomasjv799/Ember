import SwiftUI

// Up-pointing triangle (flipped for downward trends).
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// ─────────────────────────────────────────────────────────────
// Delta — trend pill. `good` overrides direction-based coloring:
// green when good, accent when not. Arrow points up/down by sign.
// ─────────────────────────────────────────────────────────────
struct Delta: View {
    @Environment(\.theme) private var theme

    var value: Int
    var good: Bool? = nil
    var suffix: String = "%"

    var body: some View {
        let up = value >= 0
        let positive = good ?? up
        let col = positive ? theme.good : theme.accentColor
        return HStack(spacing: 2) {
            Triangle()
                .fill(col)
                .frame(width: 9, height: 8)
                .rotationEffect(.degrees(up ? 0 : 180))
            Text("\(abs(value))\(suffix)")
                .font(.mono(12, 650))
                .foregroundStyle(col)
        }
    }
}
