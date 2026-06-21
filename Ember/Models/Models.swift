import SwiftUI

// ─────────────────────────────────────────────────────────────
// Today snapshot — the home dashboard's data for the current day.
// ─────────────────────────────────────────────────────────────
struct TodaySnapshot {
    var name: String
    var dateText: String          // e.g. "Saturday, June 20"
    var streakDays: Int

    var steps: Int
    var stepGoal: Int
    var restingHR: Int
    var sleepText: String         // "7h 12m"
    var sleepHours: Double        // 7.2
    var activeEnergy: Int
    var energyGoal: Int
    var exercise: Int
    var exerciseGoal: Int
    var stand: Int
    var hourlySteps: [Double]

    // Home-tile trend deltas (vs prior period)
    var hrDelta: Int
    var sleepDelta: Int
    var energyDelta: Int

    // "This week" mini-card
    var weeklyStepsTotal: Int

    var stepPercent: Int { stepGoal > 0 ? Int((Double(steps) / Double(stepGoal) * 100).rounded()) : 0 }
    var stepsToGoal: Int { max(0, stepGoal - steps) }

    // Direction semantics for the tile delta pills (drives green vs accent).
    var hrDeltaGood: Bool { hrDelta <= 0 }       // lower resting HR is better
    var sleepDeltaGood: Bool { sleepDelta >= 0 } // more sleep is better
    var energyDeltaGood: Bool { energyDelta >= 0 }
}

// ─────────────────────────────────────────────────────────────
// One row in the weekly "this week vs last" comparison.
// ─────────────────────────────────────────────────────────────
struct WeeklyMetric: Identifiable {
    var key: String
    var label: String
    var value: String
    var unit: String
    var delta: Int
    var good: Bool
    var series: [Double]
    var glyph: Glyph
    var fixedColor: Color?        // heart/sleep use a fixed hue; nil → accent
    var useAccent2: Bool = false

    var id: String { key }

    func color(_ theme: Theme) -> Color {
        if let fixedColor { return fixedColor }
        return useAccent2 ? theme.accent2Color : theme.accentColor
    }

    /// Which Detail view this row opens.
    var metricKind: MetricKind {
        switch key {
        case "hr": return .hr
        case "sleep": return .sleep
        default: return .steps
        }
    }
}

// ─────────────────────────────────────────────────────────────
// "Focus next week" recommendation card.
// ─────────────────────────────────────────────────────────────
struct FocusItem: Identifiable {
    let id = UUID()
    var title: String
    var body: String
    var glyph: Glyph
}

// ─────────────────────────────────────────────────────────────
// The weekly status report (the hero screen).
// ─────────────────────────────────────────────────────────────
struct WeeklyReport {
    var range: String             // "Jun 13 – Jun 19"
    var status: String            // "On track"
    var score: Int                // 78
    var scoreDelta: Int           // +6
    var summary: String
    var metrics: [WeeklyMetric]
    var stepsByDay: [Double]
    var dayLabels: [String]
    var stepsAvg: String          // "8,240"
    var stepsAvgDelta: Int        // 9
    var highlights: [String]
    var watchOuts: [String]
    var focus: [FocusItem]
}

// ─────────────────────────────────────────────────────────────
// One item in the Insights bullet feed.
// ─────────────────────────────────────────────────────────────
struct Insight: Identifiable {
    let id: Int
    var category: InsightCategory
    var glyph: Glyph
    var time: String
    var pinned: Bool
    var headline: String
    var detail: String
    var tag: String

    func color(_ theme: Theme) -> Color {
        switch category {
        case .heart: return Theme.heart
        case .sleep: return Theme.sleep
        default:     return theme.accentColor
        }
    }

    var metricKind: MetricKind {
        switch category {
        case .heart: return .hr
        case .sleep: return .sleep
        default:     return .steps
        }
    }
}

// ─────────────────────────────────────────────────────────────
// A chat message in the Ask-Gemma thread.
// ─────────────────────────────────────────────────────────────
struct ChatMessage: Identifiable, Codable, Equatable {
    enum Role: String, Codable { case ai, user }
    var id = UUID()
    var role: Role
    var text: String
    var isVoice: Bool = false
}

// ─────────────────────────────────────────────────────────────
// On-device model status (surfaced in Settings + onboarding).
// ─────────────────────────────────────────────────────────────
struct ModelStatus {
    var name: String              // "Gemma 3n"
    var stateLabel: String        // "Active"
    var detail: String            // "via Edge Gallery · 4-bit · 3.1 GB"
    var isActive: Bool
    var usedGB: Double            // 3.1
    var totalGB: Double           // 8
    var lastRun: String           // "Last run today, 6:02 AM"

    var storagePercent: Int { Int((usedGB / totalGB * 100).rounded()) }
}

// ─────────────────────────────────────────────────────────────
// Detail-screen data for a single metric (Steps / Heart / Sleep).
// ─────────────────────────────────────────────────────────────
struct MetricDetail {
    var title: String
    var glyph: Glyph
    var fixedColor: Color?        // nil → accent (steps)
    var fill: Bool = false
    var big: String
    var unit: String
    var goal: String
    var series: [Double]
    var labels: [String]
    var stats: [Stat]
    var note: String

    struct Stat: Identifiable {
        let id = UUID()
        var key: String
        var value: String
    }

    func color(_ theme: Theme) -> Color { fixedColor ?? theme.accentColor }
}
