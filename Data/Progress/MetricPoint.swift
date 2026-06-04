
//
//  MetricAggregator.swift
//  Agil
//
//  Wandelt WorkoutLogs in chart-fertige MetricPoints um.
//  Filtert Korrekturen heraus: pro scheduleId zählt nur der letzte Eintrag.
//  Ist dieser eine "correction" → das gesamte Workout fliegt raus.
//
//  Generisch über Metrik (Feedback, Gewicht, ...) per Value-Selector.
//

import Foundation

/// Ein Punkt für die Chart: ein Tag, ein Wert.
struct MetricPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date          // Start des Tages (Mitternacht)
    let value: Double
    let count: Int          // Anzahl Workouts an diesem Tag (für Tooltip)
}

enum MetricGranularity {
    case day
    case week
    case month

    func startOfPeriod(for date: Date, calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }()) -> Date {
        switch self {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: date)?.start
                ?? calendar.startOfDay(for: date)
        case .month:
            return calendar.dateInterval(of: .month, for: date)?.start
                ?? calendar.startOfDay(for: date)
        }
    }
}

@MainActor
struct MetricAggregator {

    /// Reduziert Logs auf die "aktiven" Completions (Korrekturen rausgefiltert).
    /// Logik: pro scheduleId nur letzten Eintrag betrachten — ist der eine
    /// completion, kommt er rein; ist der eine correction, fliegt das ganze
    /// Workout raus. Logs ohne scheduleId werden 1:1 berücksichtigt.
    static func activeCompletions(_ logs: [WorkoutLog]) -> [WorkoutLog] {
        var withoutSchedule: [WorkoutLog] = []
        var grouped: [UUID: [WorkoutLog]] = [:]

        for log in logs {
            if let sid = log.scheduleId {
                grouped[sid, default: []].append(log)
            } else if log.entryTypeEnum == .completion {
                withoutSchedule.append(log)
            }
        }

        var active: [WorkoutLog] = withoutSchedule
        for (_, group) in grouped {
            let sorted = group.sorted { $0.date < $1.date }
            if let last = sorted.last, last.entryTypeEnum == .completion {
                active.append(last)
            }
        }
        return active.sorted { $0.date < $1.date }
    }

    /// Aggregiert Logs zu MetricPoints. Pro Zeitfenster (Tag/Woche/Monat)
    /// ein Punkt mit Mittelwert der ausgewählten Metrik.
    /// Logs mit nil-Wert für die Metrik werden ignoriert.
    static func aggregate(
        logs: [WorkoutLog],
        granularity: MetricGranularity,
        valueSelector: (WorkoutLog) -> Double?
    ) -> [MetricPoint] {
        let active = activeCompletions(logs)
        let calendar = Calendar.current

        var buckets: [Date: [Double]] = [:]
        for log in active {
            guard let value = valueSelector(log) else { continue }
            let bucket = granularity.startOfPeriod(for: log.date, calendar: calendar)
            buckets[bucket, default: []].append(value)
        }

        return buckets
            .map { date, values in
                MetricPoint(
                    date: date,
                    value: values.reduce(0, +) / Double(values.count),
                    count: values.count
                )
            }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Convenience-Selectors

    static let feedbackSelector: (WorkoutLog) -> Double? = { $0.progressFeedback }
    static let ratingSelector: (WorkoutLog) -> Double? = { log in
        guard let r = log.rating else { return nil }
        return Double(r)
    }
    static let weightSelector: (WorkoutLog) -> Double? = { log in
        guard let kg = log.weightKg else { return nil }
        return Double(kg)
    }

    // MARK: - Summary

    struct Summary {
        let average: Double?
        let max: Double?
        let min: Double?
        let count: Int
    }

    static func summary(_ points: [MetricPoint]) -> Summary {
        guard !points.isEmpty else {
            return Summary(average: nil, max: nil, min: nil, count: 0)
        }
        let values = points.map(\.value)
        return Summary(
            average: values.reduce(0, +) / Double(values.count),
            max: values.max(),
            min: values.min(),
            count: points.reduce(0) { $0 + $1.count }
        )
    }
}
