import SwiftUI

// ─────────────────────────────────────────────────────────────
// Weekly — the hero Weekly Status Report. Status hero ring, the
// regenerable Gemma summary, week-vs-last metric rows, daily
// steps chart, highlights / watch-outs, focus, diet teaser.
// ─────────────────────────────────────────────────────────────
struct WeeklyView: View {
    @Environment(\.theme) private var theme
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router

    @State private var week = MockData.week
    @State private var today = MockData.today
    @State private var summary = ""
    @State private var regenerating = false
    @State private var spin = false

    var body: some View {
        ScreenScroll {
            header
            statusHero
            summarySection
            metricsSection
            dailyStepsSection
            highlightsSection
            focusSection
            dietTeaser
            footer
        }
        .privacyBanner()
        .task {
            week = await env.health.weeklyReport()
            today = await env.health.todaySnapshot()
            if env.intelligence() != nil, summary.isEmpty { await generateSummary() }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WEEKLY REPORT")
                .font(.mono(12.5))
                .tracking(0.06 * 12.5)
                .foregroundStyle(theme.text3)
            Text(week.range)
                .font(.ui(28, 740))
                .tracking(-0.025 * 28)
        }
        .padding(.horizontal, DS.headerH)
    }

    // MARK: Status hero

    private var statusHero: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(theme.accentSoft)
                .frame(width: 180, height: 180)
                .blur(radius: 8)
                .offset(x: 60, y: -60)
                .allowsHitTesting(false)

            HStack(spacing: 20) {
                Ring(size: 108, stroke: 11, value: Double(week.score), maxValue: 100,
                     gradient: [theme.accent2Color, theme.accentColor]) {
                    VStack(spacing: 2) {
                        Text("\(week.score)").font(.ui(30, 760)).tracking(-0.03 * 30)
                        Text("/ 100").font(.mono(10.5)).tracking(0.04 * 10.5).foregroundStyle(theme.text3)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle().fill(theme.good).frame(width: 6, height: 6)
                        Text(week.status).font(.ui(12.5, 650)).foregroundStyle(theme.good)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.goodSoft, in: Capsule())

                    (Text("Your health score rose ")
                        + Text("+\(week.scoreDelta) points").foregroundColor(theme.textColor).bold()
                        + Text(" this week, driven by activity and recovery gains."))
                        .font(.ui(14.5))
                        .foregroundStyle(theme.text2)
                        .lineSpacing(2)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardChrome(glow: true)
        .padding(.horizontal, DS.screenH)
    }

    // MARK: AI summary

    @ViewBuilder
    private var summarySection: some View {
        if env.hasIntelligence {
            VStack(spacing: 0) {
                HStack {
                    GemmaChip(label: "Summary · on-device")
                    Spacer()
                    Button(action: regenerate) {
                        HStack(spacing: 5) {
                            Icon(.refresh, size: 14, color: theme.text3, stroke: 2)
                                .rotationEffect(.degrees(spin ? 360 : 0))
                            Text(regenerating ? "Analyzing…" : "Regenerate")
                                .font(.mono(12.5))
                                .foregroundStyle(theme.text3)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(regenerating)
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 10)

                Card(pad: 18) {
                    Text(summary.isEmpty ? "Analyzing your week…" : summary)
                        .font(.ui(15.5))
                        .foregroundStyle(theme.textColor)
                        .lineSpacing(5)
                        .opacity(regenerating ? 0.35 : 1)
                        .animation(.easeInOut(duration: 0.3), value: regenerating)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, DS.screenH)
        } else {
            EnableIntelligenceCard(message: "Load Gemma for an AI summary of your week.")
                .padding(.horizontal, DS.screenH)
        }
    }

    private func regenerate() {
        guard !regenerating else { return }
        Task { await generateSummary() }
    }

    private func generateSummary() async {
        guard let llm = env.intelligence() else { return }
        regenerating = true
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) { spin = true }
        summary = await llm.weeklySummary(context: HealthContext.string(today: today, week: week))
        regenerating = false
        withAnimation(.linear(duration: 0.2)) { spin = false }
    }

    // MARK: Metrics (this week vs last)

    private var metricsSection: some View {
        VStack(spacing: 0) {
            SectionLabel("This week vs last")
            Card(padV: 2, padH: 18) {
                VStack(spacing: 0) {
                    ForEach(Array(week.metrics.enumerated()), id: \.element.id) { index, metric in
                        MetricRow(metric: metric) { router.open(metric.metricKind) }
                            .overlay(alignment: .top) {
                                if index > 0 {
                                    Rectangle().fill(theme.hair).frame(height: 1)
                                }
                            }
                    }
                }
            }
        }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Daily steps

    private var dailyStepsSection: some View {
        VStack(spacing: 0) {
            SectionLabel("Daily steps")
            Card(pad: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(week.stepsAvg).font(.ui(24, 720)).tracking(-0.02 * 24)
                        Text("avg/day").font(.mono(12.5)).foregroundStyle(theme.text3)
                        Spacer()
                        Delta(value: week.stepsAvgDelta, good: true)
                    }
                    BarChart(data: week.stepsByDay, labels: week.dayLabels, goal: 10000,
                             color: theme.accentColor, height: 120)
                }
            }
        }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Highlights + watch-outs

    private var highlightsSection: some View {
        VStack(spacing: 12) {
            BulletCard(glyph: .check, label: "Highlights", color: theme.good, items: week.highlights)
            BulletCard(glyph: .target, label: "Watch-outs", color: theme.accentColor, items: week.watchOuts)
        }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Focus next week

    private var focusSection: some View {
        VStack(spacing: 0) {
            SectionLabel("Focus next week")
            VStack(spacing: 10) {
                ForEach(week.focus) { item in
                    Card(pad: 16) {
                        HStack(spacing: 13) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(theme.accentSoft)
                                    .frame(width: 34, height: 34)
                                Icon(item.glyph, size: 17, color: theme.accentColor, stroke: 2,
                                     fill: item.glyph == .heart)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title).font(.ui(14.5, 650))
                                Text(item.body).font(.ui(13.5)).foregroundStyle(theme.text2).lineSpacing(2)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Diet teaser (future, disabled)

    private var dietTeaser: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 38, height: 38)
                Icon(.leaf, size: 19, color: theme.text3, stroke: 1.9)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Diet recommendations").font(.ui(14.5, 650)).foregroundStyle(theme.text2)
                    Text("SOON")
                        .font(.mono(10))
                        .tracking(0.06 * 10)
                        .foregroundStyle(theme.text3)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(theme.hairStrong, lineWidth: 1))
                }
                Text("Personalized meals from your activity & sleep, generated on-device.")
                    .font(.ui(13)).foregroundStyle(theme.text3).lineSpacing(2)
            }
            Spacer(minLength: 0)
            Icon(.lock, size: 16, color: theme.text3, stroke: 1.8)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .strokeBorder(theme.hairStrong, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Footer

    private var footer: some View {
        Text("Analyzed locally · Gemma 3n · \(week.range)")
            .font(.mono(11))
            .foregroundStyle(theme.text3)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// ─────────────────────────────────────────────────────────────
// One metric comparison row (icon · label/value · sparkline · delta).
// ─────────────────────────────────────────────────────────────
private struct MetricRow: View {
    @Environment(\.theme) private var theme
    let metric: WeeklyMetric
    var onTap: () -> Void

    var body: some View {
        let color = metric.color(theme)
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 38, height: 38)
                    Icon(metric.glyph, size: 19, color: color, stroke: 2, fill: metric.glyph == .heart)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.label).font(.ui(12.5)).foregroundStyle(theme.text2)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(metric.value).font(.ui(21, 680)).tracking(-0.02 * 21)
                        Text(metric.unit).font(.mono(11.5)).foregroundStyle(theme.text3)
                    }
                }
                Spacer(minLength: 6)
                Sparkline(data: metric.series, color: color, width: 76, height: 32)
                Delta(value: metric.delta, good: metric.good)
                    .frame(width: 52, alignment: .trailing)
            }
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────────────────
// Highlights / watch-outs card.
// ─────────────────────────────────────────────────────────────
private struct BulletCard: View {
    @Environment(\.theme) private var theme
    let glyph: Glyph
    let label: String
    let color: Color
    let items: [String]

    var body: some View {
        Card(pad: 16) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Icon(glyph, size: 16, color: color, stroke: glyph == .check ? 2.4 : 2)
                    Text(label.uppercased())
                        .font(.mono(13, 650))
                        .tracking(0.04 * 13)
                        .foregroundStyle(color)
                }
                .padding(.bottom, 12)

                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        Rectangle().fill(theme.hair).frame(height: 1).padding(.vertical, 6)
                    }
                    HStack(alignment: .top, spacing: 10) {
                        Circle().fill(color).frame(width: 5, height: 5).padding(.top, 7)
                        Text(item).font(.ui(14)).foregroundStyle(theme.text2).lineSpacing(3)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
}
