import SwiftUI

// ─────────────────────────────────────────────────────────────
// MockData — the exact placeholder values from the prototype's
// `DATA` object (and `METRIC_DETAIL`). The mock providers serve
// these so the app matches the reference screenshots immediately.
// Real data comes from HealthKit + Gemma on device.
// ─────────────────────────────────────────────────────────────
enum MockData {

    static let userName = "Aman"
    static let userInitials = "A"
    static let profileLine = "34 · 178 cm · Goal: 10k steps"

    // ── Today ──────────────────────────────────────────────────
    static let today = TodaySnapshot(
        name: userName,
        dateText: "Saturday, June 20",
        streakDays: 5,
        steps: 7420,
        stepGoal: 10000,
        restingHR: 58,
        sleepText: "7h 12m",
        sleepHours: 7.2,
        activeEnergy: 412,
        energyGoal: 600,
        exercise: 28,
        exerciseGoal: 30,
        stand: 9,
        hourlySteps: [120, 60, 0, 0, 30, 240, 880, 1100, 640, 420, 510, 980, 700, 540, 320, 260, 380, 410],
        hrDelta: -3,
        sleepDelta: -6,
        energyDelta: 4,
        weeklyStepsTotal: 57680
    )

    // ── Weekly report ──────────────────────────────────────────
    static let week = WeeklyReport(
        range: "Jun 13 – Jun 19",
        status: "On track",
        score: 78,
        scoreDelta: 6,
        summary: "You hit your 10,000-step goal on 4 of 7 days and averaged 8,240 steps daily — up 9% from last week. Resting heart rate fell 3 bpm, a sign recovery is improving. Sleep was the weak spot: you averaged 6h 48m on weeknights, below your 7h 30m target.",
        metrics: [
            WeeklyMetric(key: "steps", label: "Avg Steps", value: "8,240", unit: "/day",
                         delta: 9, good: true,
                         series: [9100, 6400, 10240, 7200, 11020, 5400, 8260],
                         glyph: .steps, fixedColor: nil),
            WeeklyMetric(key: "hr", label: "Resting HR", value: "57", unit: "bpm",
                         delta: -3, good: true,
                         series: [60, 59, 60, 58, 57, 56, 57],
                         glyph: .heart, fixedColor: Theme.heart),
            WeeklyMetric(key: "sleep", label: "Avg Sleep", value: "6h 48m", unit: "/night",
                         delta: -6, good: false,
                         series: [7.2, 6.5, 6.3, 7.0, 6.6, 7.8, 6.9],
                         glyph: .moon, fixedColor: Theme.sleep),
            WeeklyMetric(key: "energy", label: "Active Energy", value: "486", unit: "kcal/day",
                         delta: 4, good: true,
                         series: [520, 410, 610, 440, 590, 350, 480],
                         glyph: .flame, fixedColor: nil, useAccent2: true),
        ],
        stepsByDay: [9100, 6400, 10240, 7200, 11020, 5400, 8260],
        dayLabels: ["M", "T", "W", "T", "F", "S", "S"],
        stepsAvg: "8,240",
        stepsAvgDelta: 9,
        highlights: [
            "Resting heart rate is at a 6-month low of 57 bpm.",
            "Friday was your most active day — 11,020 steps and a 42-min walk.",
        ],
        watchOuts: [
            "Weeknight sleep averaged 6h 48m, 42 min under target.",
            "Two consecutive low-movement days (Sat–Sun) under 8k steps.",
        ],
        focus: [
            FocusItem(title: "Protect a 7.5h sleep window",
                      body: "Set a 10:45 PM wind-down on weeknights to close the 42-min gap.",
                      glyph: .moon),
            FocusItem(title: "Add one weekend walk",
                      body: "A 25-min walk Sat & Sun keeps your daily average above 8k.",
                      glyph: .steps),
            FocusItem(title: "Hold your HR gains",
                      body: "Keep 3 zone-2 sessions a week to maintain the lower resting rate.",
                      glyph: .heart),
        ]
    )

    // ── Insights feed ──────────────────────────────────────────
    static let insights: [Insight] = [
        Insight(id: 1, category: .activity, glyph: .steps, time: "2h ago", pinned: true,
                headline: "2,580 steps from your goal — a 22-min walk closes it",
                detail: "You're at 7,420 of 10,000 steps with 5 active hours left.",
                tag: "Today · Steps"),
        Insight(id: 2, category: .heart, glyph: .heart, time: "8h ago", pinned: false,
                headline: "Resting heart rate down 3 bpm in two weeks",
                detail: "Your aerobic base is improving — keep zone-2 sessions consistent.",
                tag: "14-day trend"),
        Insight(id: 3, category: .sleep, glyph: .moon, time: "Yesterday", pinned: false,
                headline: "Late coffee cost you ~38 min of deep sleep",
                detail: "Sleep dipped to 6h 20m after a 9:40 PM coffee. Caffeine after 2 PM is a pattern for you.",
                tag: "Pattern detected"),
        Insight(id: 4, category: .activity, glyph: .flame, time: "2 days ago", pinned: false,
                headline: "610 active kcal Wednesday — your weekly high",
                detail: "Recovery looked clean the next morning. Nice effort.",
                tag: "Energy"),
        Insight(id: 5, category: .heart, glyph: .heart, time: "3 days ago", pinned: false,
                headline: "HRV trending up — recovery looks strong",
                detail: "Heart rate variability is rising week-over-week. No action needed.",
                tag: "HRV · Recovery"),
    ]

    /// Insights-this-week summary graph values.
    static let insightsSparkline: [Double] = [1, 3, 2, 4, 2, 5, 3]
    static let insightsGenerated = 12
    static let insightsByCategory: [(InsightCategory, Int)] = [(.activity, 5), (.heart, 4), (.sleep, 3)]

    // ── On-device model ────────────────────────────────────────
    static let modelStatus = ModelStatus(
        name: "Gemma 3n",
        stateLabel: "Active",
        detail: "via Edge Gallery · 4-bit · 3.1 GB",
        isActive: true,
        usedGB: 3.1,
        totalGB: 8,
        lastRun: "Last run today, 6:02 AM"
    )

    // ── Metric detail (Steps / Heart / Sleep) ──────────────────
    static func detail(for kind: MetricKind) -> MetricDetail {
        switch kind {
        case .steps:
            return MetricDetail(
                title: "Steps", glyph: .steps, fixedColor: nil, fill: false,
                big: "7,420", unit: "steps today", goal: "Goal 10,000",
                series: today.hourlySteps,
                labels: ["6a", "", "9a", "", "12p", "", "3p", "", "6p", "", "9p", ""],
                stats: [
                    .init(key: "Goal", value: "10,000"),
                    .init(key: "Distance", value: "5.4 km"),
                    .init(key: "Flights", value: "8"),
                    .init(key: "Avg/day", value: "8,240"),
                ],
                note: "You're 2,580 steps from today's goal. Friday was your best day this week at 11,020."
            )
        case .hr:
            return MetricDetail(
                title: "Heart Rate", glyph: .heart, fixedColor: Theme.heart, fill: true,
                big: "58", unit: "bpm resting", goal: "6-month low",
                series: [62, 60, 61, 59, 60, 58, 57, 59, 58, 57, 58, 57],
                labels: ["", "Mar", "", "Apr", "", "May", "", "", "Jun", "", "", ""],
                stats: [
                    .init(key: "Resting", value: "58 bpm"),
                    .init(key: "Range today", value: "52–141"),
                    .init(key: "Walking avg", value: "92 bpm"),
                    .init(key: "HRV", value: "48 ms"),
                ],
                note: "Resting heart rate dropped 3 bpm over two weeks — a sign of improving aerobic fitness."
            )
        case .sleep:
            return MetricDetail(
                title: "Sleep", glyph: .moon, fixedColor: Theme.sleep, fill: false,
                big: "7h 12m", unit: "last night", goal: "Target 7h 30m",
                series: [7.2, 6.5, 6.3, 7.0, 6.6, 7.8, 6.9, 6.4, 7.1, 6.8, 7.2, 6.9],
                labels: ["", "", "", "", "", "past 12 nights", "", "", "", "", "", ""],
                stats: [
                    .init(key: "Asleep", value: "7h 12m"),
                    .init(key: "Deep", value: "1h 04m"),
                    .init(key: "REM", value: "1h 38m"),
                    .init(key: "Avg/night", value: "6h 48m"),
                ],
                note: "Weeknight sleep is averaging 42 min under target. A consistent 10:45 PM wind-down helps."
            )
        }
    }
}
