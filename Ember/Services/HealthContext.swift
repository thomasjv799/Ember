import Foundation

// ─────────────────────────────────────────────────────────────
// HealthContext — compact, factual summary of the user's real
// HealthKit data, injected into Gemma prompts so generated text is
// grounded in actual numbers rather than invented.
// ─────────────────────────────────────────────────────────────
enum HealthContext {
    static func string(today: TodaySnapshot, week: WeeklyReport) -> String {
        func pct(_ d: Int) -> String { "\(d >= 0 ? "+" : "")\(d)%" }
        let metrics = week.metrics
            .map { "\($0.label) \($0.value)\($0.unit) (\(pct($0.delta)))" }
            .joined(separator: "; ")
        return """
        Today: \(today.steps) of \(today.stepGoal) steps; resting HR \(today.restingHR) bpm; \
        sleep \(today.sleepText); active energy \(today.activeEnergy) kcal; \
        exercise \(today.exercise)/\(today.exerciseGoal) min.
        This week (\(week.range)): avg \(week.stepsAvg) steps/day (\(pct(week.stepsAvgDelta)) vs last week); \
        \(metrics); health score \(week.score)/100.
        """
    }
}
