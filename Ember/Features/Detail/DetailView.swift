import SwiftUI

// ─────────────────────────────────────────────────────────────
// Detail — pushed metric drill-down (Steps / Heart / Sleep):
// big value, trend chart, 2×2 stat tiles, and a Gemma note.
// ─────────────────────────────────────────────────────────────
struct DetailView: View {
    @Environment(\.theme) private var theme
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router

    let metric: MetricKind
    @State private var detail: MetricDetail

    init(metric: MetricKind) {
        self.metric = metric
        _detail = State(initialValue: MockData.detail(for: metric))
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        let color = detail.color(theme)
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DS.sectionGap) {
                header(color)
                valueCard(color)
                statsGrid
                noteCard
            }
            .padding(.top, 4)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .screenEnter()
        .safeAreaInset(edge: .top, spacing: 0) { backBar }
        .task { detail = await env.health.detail(for: metric) }
    }

    // MARK: Back bar

    private var backBar: some View {
        HStack {
            Button { router.closeDetail() } label: {
                ZStack {
                    Circle().fill(theme.surface).frame(width: 38, height: 38)
                        .overlay(Circle().strokeBorder(theme.cardBorder, lineWidth: 1))
                    Icon(.chevronL, size: 20, color: theme.textColor, stroke: 2.2)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
        .background(theme.bg)
    }

    // MARK: Header

    private func header(_ color: Color) -> some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05)).frame(width: 40, height: 40)
                Icon(detail.glyph, size: 21, color: color, stroke: 2.1, fill: detail.fill)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(detail.title).font(.ui(24, 730)).tracking(-0.025 * 24)
                Text(detail.goal).font(.mono(12)).foregroundStyle(theme.text3)
            }
        }
        .padding(.horizontal, DS.headerH)
    }

    // MARK: Value + trend

    private func valueCard(_ color: Color) -> some View {
        Card(pad: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(detail.big).font(.ui(40, 760)).tracking(-0.04 * 40).foregroundStyle(color)
                    Text(detail.unit).font(.mono(13)).foregroundStyle(theme.text3)
                }
                BarChart(data: detail.series, labels: detail.labels,
                         maxValue: (detail.series.max() ?? 1) * 1.1, color: color,
                         height: 120, highlightLast: true)
            }
        }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Stats

    private var statsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(detail.stats) { stat in
                Card(pad: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(stat.key.uppercased())
                            .font(.mono(11.5)).tracking(0.04 * 11.5).foregroundStyle(theme.text3)
                        Text(stat.value).font(.ui(20, 700)).tracking(-0.02 * 20)
                    }
                }
            }
        }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Gemma note

    private var noteCard: some View {
        Card(pad: 16) {
            HStack(alignment: .top, spacing: 12) {
                Icon(.spark, size: 18, color: theme.accentColor, stroke: 2)
                VStack(alignment: .leading, spacing: 10) {
                    Text(detail.note).font(.ui(14.5)).foregroundStyle(theme.textColor).lineSpacing(3)
                    GemmaChip(small: true, label: "Gemma · on-device")
                }
            }
        }
        .padding(.horizontal, DS.screenH)
    }
}
