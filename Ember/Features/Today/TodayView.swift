import SwiftUI

// ─────────────────────────────────────────────────────────────
// Today — the home dashboard. Streak, weekly-report entry, steps
// ring, 2×2 metric grid, this-week mini chart, Gemma suggestion.
// ─────────────────────────────────────────────────────────────
struct TodayView: View {
    @Environment(\.theme) private var theme
    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router

    @State private var snap = MockData.today
    @State private var week = MockData.week
    @State private var suggestion = MockData.insights[0].detail

    var body: some View {
        ScreenScroll {
            header
            reportReadyCard
            stepsCard
            metricGrid
            thisWeekSection
            suggestionSection
            footer
        }
        .privacyBanner()
        .task {
            snap = await env.health.todaySnapshot()
            week = await env.health.weeklyReport()
            if let llm = env.intelligence() {
                suggestion = await llm.dailySuggestion(context: HealthContext.string(today: snap, week: week))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(snap.dateText)
                    .font(.mono(13))
                    .foregroundStyle(theme.text3)
                Spacer()
                HStack(spacing: 5) {
                    FlickerFlame()
                    Text("\(snap.streakDays)-day streak")
                        .font(.mono(11.5, 700))
                        .foregroundStyle(theme.accentColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(theme.accentSoft, in: Capsule())
                .overlay(Capsule().strokeBorder(theme.accentLine, lineWidth: 1))
            }
            Text("Good morning, \(env.settings.displayName) 👋")
                .font(.ui(27, 740))
                .tracking(-0.025 * 27)
        }
        .padding(.horizontal, DS.headerH)
    }

    // MARK: Weekly report ready

    private var reportReadyCard: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(theme.accentSoft)
                .frame(width: 130, height: 130)
                .blur(radius: 8)
                .offset(x: 34, y: -52)
                .allowsHitTesting(false)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(theme.accentColor)
                        .frame(width: 44, height: 44)
                    Icon(.weekly, size: 22, color: Theme.darkOnAccent, stroke: 2.1)
                }
                .glowPulse()

                VStack(alignment: .leading, spacing: 3) {
                    Text("Your weekly report is ready")
                        .font(.ui(15.5, 680))
                    HStack(spacing: 6) {
                        LiveDot(color: theme.good, size: 5)
                        Text("\(week.status) · score \(week.score) · \(week.range)")
                            .font(.ui(12.5))
                            .foregroundStyle(theme.text2)
                    }
                }
                Spacer(minLength: 8)
                Icon(.chevron, size: 18, color: theme.text3, stroke: 2.2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardChrome(glow: true)
        .contentShape(Rectangle())
        .onTapGesture { router.select(.weekly) }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Steps focus

    private var stepsCard: some View {
        Card(pad: 18) {
            HStack(spacing: 20) {
                Ring(size: 120, stroke: 12, value: Double(snap.steps), maxValue: Double(snap.stepGoal),
                     gradient: [theme.accent2Color, theme.accentColor]) {
                    VStack(spacing: 1) {
                        Icon(.steps, size: 20, color: theme.accentColor, stroke: 2.2)
                        Text(String(format: "%.1fk", Double(snap.steps) / 1000))
                            .font(.ui(25, 740))
                            .tracking(-0.03 * 25)
                            .padding(.top, 2)
                        Text("of \(snap.stepGoal / 1000)k")
                            .font(.mono(10))
                            .foregroundStyle(theme.text3)
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("STEPS TODAY")
                        .font(.mono(12.5))
                        .tracking(0.06 * 12.5)
                        .foregroundStyle(theme.text3)
                        .padding(.bottom, 4)
                    Text(snap.steps.formatted(.number.grouping(.automatic)))
                        .font(.ui(32, 760))
                        .tracking(-0.03 * 32)
                    (Text("\(snap.stepsToGoal) steps").foregroundColor(theme.accentColor).bold()
                        + Text(" to your goal — about a 22-min walk."))
                        .font(.ui(13.5))
                        .foregroundStyle(theme.text2)
                        .lineSpacing(2)
                        .padding(.top, 8)
                }
            }
        }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Metric grid

    private var metricGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MetricTile(glyph: .heart, color: Theme.heart, fill: true,
                           value: snap.restingHR > 0 ? "\(snap.restingHR)" : "—", unit: "bpm", label: "Resting heart rate") {
                    Delta(value: snap.hrDelta, good: snap.hrDeltaGood)
                } onTap: { router.open(.hr) }
                MetricTile(glyph: .moon, color: Theme.sleep,
                           value: snap.sleepText, unit: "", label: "Last night's sleep") {
                    Delta(value: snap.sleepDelta, good: snap.sleepDeltaGood)
                } onTap: { router.open(.sleep) }
            }
            HStack(spacing: 12) {
                MetricTile(glyph: .flame, color: theme.accent2Color,
                           value: "\(snap.activeEnergy)", unit: "kcal", label: "Active energy") {
                    Delta(value: snap.energyDelta, good: snap.energyDeltaGood)
                }
                MetricTile(glyph: .spark, color: theme.accentColor,
                           value: "\(snap.exercise)", unit: "min", label: "Exercise") {
                    Text("\(snap.exercise)/\(snap.exerciseGoal)")
                        .font(.mono(11))
                        .foregroundStyle(theme.text3)
                }
            }
        }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: This week

    private var thisWeekSection: some View {
        VStack(spacing: 0) {
            SectionLabel("This week", action: "Report") { router.select(.weekly) }
            Card(pad: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(snap.weeklyStepsTotal.formatted(.number.grouping(.automatic)))
                            .font(.ui(22, 720))
                            .tracking(-0.02 * 22)
                        Text("steps · 7 days")
                            .font(.mono(12.5))
                            .foregroundStyle(theme.text3)
                        Spacer()
                        Delta(value: week.stepsAvgDelta, good: true)
                    }
                    BarChart(data: week.stepsByDay, labels: week.dayLabels, goal: 10000,
                             color: theme.accentColor, height: 92)
                }
            }
        }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Suggestion

    @ViewBuilder
    private var suggestionSection: some View {
        VStack(spacing: 0) {
            SectionLabel("Today's suggestion", action: env.hasIntelligence ? "See all" : nil) { router.select(.insights) }
            if env.hasIntelligence {
                Card(pad: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(theme.accentSoft)
                                .frame(width: 36, height: 36)
                            Icon(.spark, size: 18, color: theme.accentColor, stroke: 2)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text(suggestion)
                                .font(.ui(14.5))
                                .foregroundStyle(theme.textColor)
                                .lineSpacing(3)
                            GemmaChip(small: true, label: "Gemma · on-device")
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { router.select(.insights) }
            } else {
                EnableIntelligenceCard(message: "Load Gemma to get a daily suggestion generated from your data.")
            }
        }
        .padding(.horizontal, DS.screenH)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Icon(.shield, size: 12, color: theme.text3, stroke: 1.8)
            Text("Synced from Apple Health · processed on device")
                .font(.mono(11))
                .foregroundStyle(theme.text3)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 2)
    }
}

// ─────────────────────────────────────────────────────────────
// Metric tile — one cell of the 2×2 grid.
// ─────────────────────────────────────────────────────────────
private struct MetricTile<Trailing: View>: View {
    @Environment(\.theme) private var theme

    let glyph: Glyph
    let color: Color
    var fill: Bool = false
    let value: String
    let unit: String
    let label: String
    @ViewBuilder var trailing: () -> Trailing
    var onTap: (() -> Void)? = nil

    var body: some View {
        Card(pad: 15) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 32, height: 32)
                        Icon(glyph, size: 17, color: color, stroke: 2, fill: fill)
                    }
                    Spacer()
                    trailing()
                }
                .padding(.bottom, 14)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.ui(23, 700))
                        .tracking(-0.02 * 23)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.mono(11.5))
                            .foregroundStyle(theme.text3)
                    }
                }
                Text(label)
                    .font(.ui(12.5))
                    .foregroundStyle(theme.text2)
                    .padding(.top, 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}
