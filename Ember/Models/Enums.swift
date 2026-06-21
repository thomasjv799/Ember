import Foundation

// ─────────────────────────────────────────────────────────────
// Which metric a Detail view is showing (reused for Steps / Heart / Sleep).
// ─────────────────────────────────────────────────────────────
enum MetricKind: String, Identifiable, Hashable {
    case steps, hr, sleep
    var id: String { rawValue }
}

// ─────────────────────────────────────────────────────────────
// Insight categories — also drive the Insights filter chips.
// ─────────────────────────────────────────────────────────────
enum InsightCategory: String, CaseIterable, Identifiable {
    case all      = "All"
    case activity = "Activity"
    case heart    = "Heart"
    case sleep    = "Sleep"
    var id: String { rawValue }
}
