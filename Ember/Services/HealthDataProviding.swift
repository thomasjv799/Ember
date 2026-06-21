import Foundation

// ─────────────────────────────────────────────────────────────
// HealthDataProviding — the app's health data behind a protocol.
// MockHealthProvider serves the screenshot values (simulator).
// HealthKitProvider reads real Apple Health data on device.
// ─────────────────────────────────────────────────────────────
protocol HealthDataProviding {
    func requestAuthorization() async -> Bool
    func todaySnapshot() async -> TodaySnapshot
    func weeklyReport() async -> WeeklyReport
    func insights() async -> [Insight]
    func detail(for kind: MetricKind) async -> MetricDetail
}

// MARK: - Mock (simulator / previews)

struct MockHealthProvider: HealthDataProviding {
    func requestAuthorization() async -> Bool { true }
    func todaySnapshot() async -> TodaySnapshot { MockData.today }
    func weeklyReport() async -> WeeklyReport { MockData.week }
    func insights() async -> [Insight] { MockData.insights }
    func detail(for kind: MetricKind) async -> MetricDetail { MockData.detail(for: kind) }
}

// Shared formatting + goals.
enum HealthFormat {
    static let stepGoal = 10_000
    static let energyGoal = 600
    static let exerciseGoal = 30
    static let sleepTargetHours = 7.5

    static func hoursMinutes(_ hours: Double) -> String {
        guard hours > 0 else { return "—" }
        let total = Int((hours * 60).rounded())
        return "\(total / 60)h \(String(format: "%02d", total % 60))m"
    }
    static func grouped(_ n: Int) -> String { n.formatted(.number.grouping(.automatic)) }
    static func pct(_ now: Double, _ prev: Double) -> Int {
        prev > 0 ? Int((((now - prev) / prev) * 100).rounded()) : 0
    }
}

// MARK: - HealthKit (real, on device)

#if canImport(HealthKit)
import HealthKit

final class HealthKitProvider: HealthDataProviding {
    private let store = HKHealthStore()
    private let bpm = HKUnit.count().unitDivided(by: .minute())
    private let cal = Calendar.current

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let quantities: [HKQuantityTypeIdentifier] = [
            .stepCount, .restingHeartRate, .heartRateVariabilitySDNN, .heartRate,
            .activeEnergyBurned, .appleExerciseTime, .distanceWalkingRunning, .flightsClimbed,
        ]
        for id in quantities { if let t = HKObjectType.quantityType(forIdentifier: id) { types.insert(t) } }
        if let s = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(s) }
        return types
    }

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        return await withCheckedContinuation { c in
            store.requestAuthorization(toShare: [], read: readTypes) { ok, _ in c.resume(returning: ok) }
        }
    }

    // MARK: Query helpers

    private func statistic(_ id: HKQuantityTypeIdentifier, unit: HKUnit, options: HKStatisticsOptions,
                           start: Date, end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { c in
            let pred = HKQuery.predicateForSamples(withStart: start, end: end)
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: options) { _, s, _ in
                let qty = options.contains(.cumulativeSum) ? s?.sumQuantity()
                    : options.contains(.discreteMin) ? s?.minimumQuantity()
                    : options.contains(.discreteMax) ? s?.maximumQuantity()
                    : s?.averageQuantity()
                c.resume(returning: qty?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func mostRecent(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { c in
            let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: sort) { _, samples, _ in
                c.resume(returning: (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    /// Per-day values for the last `days` days (oldest → newest), 0 where missing.
    private func dailyValues(_ id: HKQuantityTypeIdentifier, unit: HKUnit,
                             options: HKStatisticsOptions, days: Int) async -> [Double] {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return Array(repeating: 0, count: days) }
        let end = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -(days - 1), to: end) else { return Array(repeating: 0, count: days) }
        var interval = DateComponents(); interval.day = 1
        return await withCheckedContinuation { c in
            let q = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: nil,
                                                options: options, anchorDate: start, intervalComponents: interval)
            q.initialResultsHandler = { _, coll, _ in
                var out: [Double] = []
                let upper = self.cal.date(byAdding: .day, value: 1, to: end) ?? end
                coll?.enumerateStatistics(from: start, to: upper) { stat, _ in
                    let qty = options.contains(.cumulativeSum) ? stat.sumQuantity() : stat.averageQuantity()
                    out.append(qty?.doubleValue(for: unit) ?? 0)
                }
                while out.count < days { out.append(0) }
                c.resume(returning: Array(out.suffix(days)))
            }
            store.execute(q)
        }
    }

    private static let asleepValues: Set<Int> = [
        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
        HKCategoryValueSleepAnalysis.asleepREM.rawValue,
        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
    ]

    /// Hours asleep per day for the last `days` days (bucketed by the day the sleep ended).
    private func sleepByDay(days: Int) async -> [Double] {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return Array(repeating: 0, count: days) }
        let end = Date()
        let start = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: end)) ?? end
        return await withCheckedContinuation { c in
            let pred = HKQuery.predicateForSamples(withStart: start, end: end)
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                var byDay: [Date: Double] = [:]
                for s in (samples as? [HKCategorySample] ?? []) where Self.asleepValues.contains(s.value) {
                    let day = self.cal.startOfDay(for: s.endDate)
                    byDay[day, default: 0] += s.endDate.timeIntervalSince(s.startDate)
                }
                var out: [Double] = []
                for i in stride(from: days - 1, through: 0, by: -1) {
                    let day = self.cal.startOfDay(for: self.cal.date(byAdding: .day, value: -i, to: end) ?? end)
                    out.append((byDay[day] ?? 0) / 3600)
                }
                c.resume(returning: out)
            }
            store.execute(q)
        }
    }

    /// Last night's sleep broken into total / deep / REM hours.
    private func lastNightSleep() async -> (total: Double, deep: Double, rem: Double) {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return (0, 0, 0) }
        let end = Date()
        let start = cal.date(byAdding: .hour, value: -24, to: end) ?? end
        return await withCheckedContinuation { c in
            let pred = HKQuery.predicateForSamples(withStart: start, end: end)
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                var total = 0.0, deep = 0.0, rem = 0.0
                for s in (samples as? [HKCategorySample] ?? []) {
                    let dur = s.endDate.timeIntervalSince(s.startDate)
                    if Self.asleepValues.contains(s.value) { total += dur }
                    if s.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue { deep += dur }
                    if s.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue { rem += dur }
                }
                c.resume(returning: (total / 3600, deep / 3600, rem / 3600))
            }
            store.execute(q)
        }
    }

    private func hourlySteps() async -> [Double] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return [] }
        let start = cal.startOfDay(for: Date())
        var interval = DateComponents(); interval.hour = 1
        return await withCheckedContinuation { c in
            let q = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: nil,
                                                options: .cumulativeSum, anchorDate: start, intervalComponents: interval)
            q.initialResultsHandler = { _, coll, _ in
                var out: [Double] = []
                coll?.enumerateStatistics(from: start, to: Date()) { stat, _ in
                    out.append(stat.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                }
                c.resume(returning: out)
            }
            store.execute(q)
        }
    }

    // MARK: Aggregation helpers

    private func avg(_ values: ArraySlice<Double>) -> Double {
        let nz = values.filter { $0 > 0 }
        return nz.isEmpty ? 0 : nz.reduce(0, +) / Double(nz.count)
    }

    private func score(steps: Double, sleep: Double, hr: Double) -> Int {
        let s = min(1, steps / Double(HealthFormat.stepGoal)) * 40
        let sl = min(1, sleep / HealthFormat.sleepTargetHours) * 30
        let h = hr > 0 ? min(1, max(0, (80 - hr) / 40)) * 30 : 0
        return Int((s + sl + h).rounded())
    }

    // MARK: HealthDataProviding

    func todaySnapshot() async -> TodaySnapshot {
        let start = cal.startOfDay(for: Date())
        let now = Date()

        let steps = Int((await statistic(.stepCount, unit: .count(), options: .cumulativeSum, start: start, end: now)) ?? 0)
        let energy = Int((await statistic(.activeEnergyBurned, unit: .kilocalorie(), options: .cumulativeSum, start: start, end: now)) ?? 0)
        let exercise = Int((await statistic(.appleExerciseTime, unit: .minute(), options: .cumulativeSum, start: start, end: now)) ?? 0)
        let restingHR = Int(((await mostRecent(.restingHeartRate, unit: bpm)) ?? 0).rounded())

        let stepDays = await dailyValues(.stepCount, unit: .count(), options: .cumulativeSum, days: 14)
        let hrDays = await dailyValues(.restingHeartRate, unit: bpm, options: .discreteAverage, days: 14)
        let energyDays = await dailyValues(.activeEnergyBurned, unit: .kilocalorie(), options: .cumulativeSum, days: 14)
        let sleepDays = await sleepByDay(days: 14)
        let lastNight = sleepDays.last ?? 0

        let df = DateFormatter(); df.dateFormat = "EEEE, MMMM d"

        return TodaySnapshot(
            name: MockData.userName,
            dateText: df.string(from: now),
            streakDays: stepStreak(stepDays),
            steps: steps,
            stepGoal: HealthFormat.stepGoal,
            restingHR: restingHR,
            sleepText: HealthFormat.hoursMinutes(lastNight),
            sleepHours: lastNight,
            activeEnergy: energy,
            energyGoal: HealthFormat.energyGoal,
            exercise: exercise,
            exerciseGoal: HealthFormat.exerciseGoal,
            stand: 0,
            hourlySteps: await hourlySteps(),
            hrDelta: HealthFormat.pct(avg(hrDays.suffix(7)), avg(hrDays.prefix(7))),
            sleepDelta: HealthFormat.pct(avg(sleepDays.suffix(7)), avg(sleepDays.prefix(7))),
            energyDelta: HealthFormat.pct(avg(energyDays.suffix(7)), avg(energyDays.prefix(7))),
            weeklyStepsTotal: Int(stepDays.suffix(7).reduce(0, +))
        )
    }

    private func stepStreak(_ daily: [Double]) -> Int {
        var streak = 0
        // Count back from yesterday so an unfinished today doesn't break the streak.
        for v in daily.dropLast().reversed() {
            if Int(v) >= HealthFormat.stepGoal { streak += 1 } else { break }
        }
        return streak
    }

    func weeklyReport() async -> WeeklyReport {
        let stepDays = await dailyValues(.stepCount, unit: .count(), options: .cumulativeSum, days: 14)
        let hrDays = await dailyValues(.restingHeartRate, unit: bpm, options: .discreteAverage, days: 14)
        let energyDays = await dailyValues(.activeEnergyBurned, unit: .kilocalorie(), options: .cumulativeSum, days: 14)
        let sleepDays = await sleepByDay(days: 14)

        let stepsW = avg(stepDays.suffix(7)), stepsP = avg(stepDays.prefix(7))
        let hrW = avg(hrDays.suffix(7)), hrP = avg(hrDays.prefix(7))
        let sleepW = avg(sleepDays.suffix(7)), sleepP = avg(sleepDays.prefix(7))
        let energyW = avg(energyDays.suffix(7)), energyP = avg(energyDays.prefix(7))

        let metrics: [WeeklyMetric] = [
            WeeklyMetric(key: "steps", label: "Avg Steps", value: HealthFormat.grouped(Int(stepsW)), unit: "/day",
                         delta: HealthFormat.pct(stepsW, stepsP), good: stepsW >= stepsP,
                         series: Array(stepDays.suffix(7)), glyph: .steps, fixedColor: nil),
            WeeklyMetric(key: "hr", label: "Resting HR", value: hrW > 0 ? "\(Int(hrW))" : "—", unit: "bpm",
                         delta: HealthFormat.pct(hrW, hrP), good: hrW <= hrP,
                         series: Array(hrDays.suffix(7)), glyph: .heart, fixedColor: Theme.heart),
            WeeklyMetric(key: "sleep", label: "Avg Sleep", value: HealthFormat.hoursMinutes(sleepW), unit: "/night",
                         delta: HealthFormat.pct(sleepW, sleepP), good: sleepW >= sleepP,
                         series: Array(sleepDays.suffix(7)), glyph: .moon, fixedColor: Theme.sleep),
            WeeklyMetric(key: "energy", label: "Active Energy", value: "\(Int(energyW))", unit: "kcal/day",
                         delta: HealthFormat.pct(energyW, energyP), good: energyW >= energyP,
                         series: Array(energyDays.suffix(7)), glyph: .flame, fixedColor: nil, useAccent2: true),
        ]

        let thisScore = score(steps: stepsW, sleep: sleepW, hr: hrW)
        let lastScore = score(steps: stepsP, sleep: sleepP, hr: hrP)

        let weekDays = Array(stepDays.suffix(7))
        let labels = lastSevenDayLabels()

        return WeeklyReport(
            range: weekRangeText(),
            status: thisScore >= 75 ? "On track" : thisScore >= 50 ? "Getting there" : "Needs focus",
            score: thisScore,
            scoreDelta: thisScore - lastScore,
            summary: "",   // generated by Gemma in the UI when a model is loaded
            metrics: metrics,
            stepsByDay: weekDays,
            dayLabels: labels,
            stepsAvg: HealthFormat.grouped(Int(stepsW)),
            stepsAvgDelta: HealthFormat.pct(stepsW, stepsP),
            highlights: weeklyHighlights(stepsW: stepsW, hrW: hrW, hrP: hrP, sleepW: sleepW),
            watchOuts: weeklyWatchOuts(sleepW: sleepW, stepDays: weekDays),
            focus: MockData.week.focus   // generic, data-agnostic recommendations
        )
    }

    private func weeklyHighlights(stepsW: Double, hrW: Double, hrP: Double, sleepW: Double) -> [String] {
        var out: [String] = []
        if stepsW > 0 { out.append("Averaged \(HealthFormat.grouped(Int(stepsW))) steps a day this week.") }
        if hrW > 0 && hrW <= hrP { out.append("Resting heart rate held at \(Int(hrW)) bpm.") }
        if sleepW >= HealthFormat.sleepTargetHours { out.append("Sleep met your \(HealthFormat.hoursMinutes(HealthFormat.sleepTargetHours)) target.") }
        return out.isEmpty ? ["Keep logging activity to surface highlights."] : Array(out.prefix(2))
    }

    private func weeklyWatchOuts(sleepW: Double, stepDays: [Double]) -> [String] {
        var out: [String] = []
        if sleepW > 0 && sleepW < HealthFormat.sleepTargetHours {
            let gap = Int((HealthFormat.sleepTargetHours - sleepW) * 60)
            out.append("Sleep averaged \(HealthFormat.hoursMinutes(sleepW)), \(gap) min under target.")
        }
        let lowDays = stepDays.filter { $0 > 0 && Int($0) < HealthFormat.stepGoal }.count
        if lowDays > 0 { out.append("\(lowDays) day\(lowDays == 1 ? "" : "s") under your step goal.") }
        return out.isEmpty ? ["Nothing flagged — nice consistency."] : Array(out.prefix(2))
    }

    func insights() async -> [Insight] { [] }   // Insights are Gemma-generated from real data in the UI.

    func detail(for kind: MetricKind) async -> MetricDetail {
        switch kind {
        case .steps:  return await stepsDetail()
        case .hr:     return await hrDetail()
        case .sleep:  return await sleepDetail()
        }
    }

    private func stepsDetail() async -> MetricDetail {
        let start = cal.startOfDay(for: Date()); let now = Date()
        let today = Int((await statistic(.stepCount, unit: .count(), options: .cumulativeSum, start: start, end: now)) ?? 0)
        let distance = (await statistic(.distanceWalkingRunning, unit: .meterUnit(with: .kilo), options: .cumulativeSum, start: start, end: now)) ?? 0
        let flights = Int((await statistic(.flightsClimbed, unit: .count(), options: .cumulativeSum, start: start, end: now)) ?? 0)
        let week = await dailyValues(.stepCount, unit: .count(), options: .cumulativeSum, days: 7)
        let hourly = await hourlySteps()
        return MetricDetail(
            title: "Steps", glyph: .steps, fixedColor: nil, fill: false,
            big: HealthFormat.grouped(today), unit: "steps today", goal: "Goal \(HealthFormat.grouped(HealthFormat.stepGoal))",
            series: hourly.isEmpty ? week : hourly, labels: [],
            stats: [
                .init(key: "Goal", value: HealthFormat.grouped(HealthFormat.stepGoal)),
                .init(key: "Distance", value: String(format: "%.1f km", distance)),
                .init(key: "Flights", value: "\(flights)"),
                .init(key: "Avg/day", value: HealthFormat.grouped(Int(avg(week.suffix(7))))),
            ],
            note: "")
    }

    private func hrDetail() async -> MetricDetail {
        let start = cal.startOfDay(for: Date()); let now = Date()
        let resting = Int(((await mostRecent(.restingHeartRate, unit: bpm)) ?? 0).rounded())
        let minHR = (await statistic(.heartRate, unit: bpm, options: .discreteMin, start: start, end: now)) ?? 0
        let maxHR = (await statistic(.heartRate, unit: bpm, options: .discreteMax, start: start, end: now)) ?? 0
        let hrv = (await mostRecent(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))) ?? 0
        let week = await dailyValues(.restingHeartRate, unit: bpm, options: .discreteAverage, days: 12)
        return MetricDetail(
            title: "Heart Rate", glyph: .heart, fixedColor: Theme.heart, fill: true,
            big: resting > 0 ? "\(resting)" : "—", unit: "bpm resting", goal: "Resting heart rate",
            series: week, labels: [],
            stats: [
                .init(key: "Resting", value: resting > 0 ? "\(resting) bpm" : "—"),
                .init(key: "Range today", value: (minHR > 0 && maxHR > 0) ? "\(Int(minHR))–\(Int(maxHR))" : "—"),
                .init(key: "HRV", value: hrv > 0 ? "\(Int(hrv)) ms" : "—"),
                .init(key: "Avg/day", value: avg(week.suffix(7)) > 0 ? "\(Int(avg(week.suffix(7)))) bpm" : "—"),
            ],
            note: "")
    }

    private func sleepDetail() async -> MetricDetail {
        let nights = await sleepByDay(days: 12)
        let lastNight = await lastNightSleep()
        return MetricDetail(
            title: "Sleep", glyph: .moon, fixedColor: Theme.sleep, fill: false,
            big: HealthFormat.hoursMinutes(lastNight.total), unit: "last night",
            goal: "Target \(HealthFormat.hoursMinutes(HealthFormat.sleepTargetHours))",
            series: nights, labels: [],
            stats: [
                .init(key: "Asleep", value: HealthFormat.hoursMinutes(lastNight.total)),
                .init(key: "Deep", value: HealthFormat.hoursMinutes(lastNight.deep)),
                .init(key: "REM", value: HealthFormat.hoursMinutes(lastNight.rem)),
                .init(key: "Avg/night", value: HealthFormat.hoursMinutes(avg(nights.suffix(7)))),
            ],
            note: "")
    }

    // MARK: Date helpers

    private func weekRangeText() -> String {
        let df = DateFormatter(); df.dateFormat = "MMM d"
        let end = Date()
        let start = cal.date(byAdding: .day, value: -6, to: end) ?? end
        return "\(df.string(from: start)) – \(df.string(from: end))"
    }

    private func lastSevenDayLabels() -> [String] {
        let df = DateFormatter(); df.dateFormat = "EEEEE"   // single-letter weekday
        let end = Date()
        return (0..<7).reversed().map { i in
            df.string(from: cal.date(byAdding: .day, value: -i, to: end) ?? end)
        }
    }
}
#endif
