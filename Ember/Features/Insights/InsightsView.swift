import SwiftUI

// ─────────────────────────────────────────────────────────────
// Insights — Gemma-generated insights from the user's real data.
// Gated on a loaded model (per the on-device-only design).
// ─────────────────────────────────────────────────────────────
struct InsightsView: View {
    @Environment(\.theme) private var theme
    @Environment(AppEnvironment.self) private var env

    @State private var insights: [String] = []
    @State private var loading = false
    @State private var today = MockData.today
    @State private var week = MockData.week

    var body: some View {
        ScreenScroll {
            header
            if env.hasIntelligence {
                content
            } else {
                EnableIntelligenceCard(message: "Load Gemma to generate insights from your health data.")
                    .padding(.horizontal, DS.screenH)
            }
        }
        .privacyBanner()
        .task {
            today = await env.health.todaySnapshot()
            week = await env.health.weeklyReport()
            if env.hasIntelligence, insights.isEmpty { await generate() }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(loading ? "Analyzing your data…" : "Generated on-device")
                .font(.mono(13)).foregroundStyle(theme.text3)
            Text("Insights").font(.ui(27, 740)).tracking(-0.025 * 27)
        }
        .padding(.horizontal, DS.headerH)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 14) {
            if loading && insights.isEmpty {
                Card(pad: 16) {
                    HStack(spacing: 10) {
                        ProgressView().tint(theme.accentColor)
                        Text("Reading your last 7 days…").font(.ui(14.5)).foregroundStyle(theme.text2)
                    }
                }
            } else if insights.isEmpty {
                Card(pad: 16) {
                    Text("No insights yet — tap Regenerate to analyze your data.")
                        .font(.ui(14.5)).foregroundStyle(theme.text2)
                }
            } else {
                ForEach(Array(insights.enumerated()), id: \.offset) { _, line in
                    insightRow(line)
                }
            }

            HStack {
                GemmaChip(small: true, label: "Generated on-device")
                Spacer()
                Button { Task { await generate() } } label: {
                    HStack(spacing: 5) {
                        Icon(.refresh, size: 13, color: theme.text3, stroke: 2)
                        Text("Regenerate").font(.mono(12.5)).foregroundStyle(theme.text3)
                    }
                }
                .buttonStyle(.plain)
                .disabled(loading)
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, DS.screenH)
    }

    private func insightRow(_ text: String) -> some View {
        Card(pad: 16) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(theme.accentColor)
                    .frame(width: 9, height: 9)
                    .shadow(color: theme.accentColor, radius: 4)
                    .padding(.top, 5)
                Text(text)
                    .font(.ui(14.5))
                    .foregroundStyle(theme.textColor)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
    }

    private func generate() async {
        guard let llm = env.intelligence() else { return }
        loading = true
        insights = await llm.insights(context: HealthContext.string(today: today, week: week))
        loading = false
    }
}
