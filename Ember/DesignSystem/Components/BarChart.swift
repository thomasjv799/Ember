import SwiftUI

// ─────────────────────────────────────────────────────────────
// Bar chart with an optional dashed goal line. Bars that meet the
// goal are accent-filled; others are muted. Supports highlighting
// the last bar (for the Detail trend). Bars grow in over .7s.
// ─────────────────────────────────────────────────────────────
struct BarChart: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var data: [Double]
    var labels: [String]? = nil
    var maxValue: Double? = nil
    var goal: Double? = nil
    var color: Color = .red
    var height: CGFloat = 132
    var highlightLast: Bool = false

    @State private var grown: CGFloat = 0

    private var top: Double {
        if let maxValue { return maxValue }
        let m = max(data.max() ?? 0, goal ?? 0)
        return m * 1.08
    }

    private func goalLabel(_ g: Double) -> String {
        g >= 1000 ? "\(Int(g / 1000))k" : "\(Int(g))"
    }

    private func fill(for value: Double, isLast: Bool) -> Color {
        let met = goal == nil ? true : value >= goal!
        if isLast && goal == nil { return color }
        if met { return goal != nil ? color : color.opacity(0.75) }
        return Color.white.opacity(0.13)
    }

    var body: some View {
        VStack(spacing: 7) {
            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data.indices, id: \.self) { i in
                        bar(index: i)
                    }
                }
                .frame(height: height)

                if let goal {
                    goalLine(goal)
                }
            }
            .frame(height: height)
            .padding(.vertical, 4)

            if let labels {
                HStack(spacing: 8) {
                    ForEach(labels.indices, id: \.self) { i in
                        Text(labels[i])
                            .font(.mono(10.5))
                            .foregroundStyle(theme.text3)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .onAppear {
            if reduceMotion { grown = 1 }
            else { withAnimation(Motion.barGrow) { grown = 1 } }
        }
    }

    private func bar(index i: Int) -> some View {
        let value = data[i]
        let isLast = highlightLast && i == data.count - 1
        let hPct = max(3, value / top * 100)
        let barHeight = CGFloat(hPct / 100) * height
        return Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(fill(for: value, isLast: isLast))
                    .frame(height: barHeight * grown)
                    .overlay {
                        if isLast {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(color, lineWidth: 1.5)
                                .padding(-1.5)
                                .opacity(Double(grown))
                        }
                    }
            }
    }

    private func goalLine(_ g: Double) -> some View {
        let y = CGFloat(g / top) * height
        return HLine()
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            .foregroundStyle(Color.white.opacity(0.22))
            .frame(height: 1.5)
            .overlay(alignment: .topTrailing) {
                Text("GOAL \(goalLabel(g))")
                    .font(.mono(10))
                    .tracking(0.2)
                    .foregroundStyle(theme.text3)
                    .offset(y: -15)
            }
            .offset(y: -y)
    }
}

// Horizontal line shape (so it can carry a dash pattern).
private struct HLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return p
    }
}
