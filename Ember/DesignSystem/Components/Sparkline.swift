import SwiftUI

// ─────────────────────────────────────────────────────────────
// Sparkline — small trend line with a faded area fill and an
// end dot. Geometry matches the prototype's SVG sparkline.
// ─────────────────────────────────────────────────────────────
struct Sparkline: View {
    var data: [Double]
    var color: Color
    var width: CGFloat = 96
    var height: CGFloat = 34
    var fillFade: Bool = true

    private func points(in size: CGSize) -> [CGPoint] {
        guard data.count > 1 else {
            return [CGPoint(x: 0, y: size.height / 2), CGPoint(x: size.width, y: size.height / 2)]
        }
        let mn = data.min() ?? 0
        let mx = data.max() ?? 0
        let span = (mx - mn) == 0 ? 1 : (mx - mn)
        return data.enumerated().map { i, d in
            let x = CGFloat(i) / CGFloat(data.count - 1) * size.width
            let y = size.height - 3 - CGFloat((d - mn) / span) * (size.height - 6)
            return CGPoint(x: x, y: y)
        }
    }

    var body: some View {
        Canvas { context, size in
            let pts = points(in: size)
            guard let first = pts.first, let last = pts.last else { return }

            var line = Path()
            line.addLines(pts)

            if fillFade {
                var area = Path()
                area.addLines(pts)
                area.addLine(to: CGPoint(x: last.x, y: size.height))
                area.addLine(to: CGPoint(x: first.x, y: size.height))
                area.closeSubpath()
                context.fill(
                    area,
                    with: .linearGradient(
                        Gradient(colors: [color.opacity(0.22), color.opacity(0)]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
            }

            context.stroke(
                line,
                with: .color(color),
                style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
            )

            let r: CGFloat = 2.6
            context.fill(
                Path(ellipseIn: CGRect(x: last.x - r, y: last.y - r, width: r * 2, height: r * 2)),
                with: .color(color)
            )
        }
        .frame(width: width, height: height)
    }
}
