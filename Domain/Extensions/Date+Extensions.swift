
import Foundation
import SwiftUI



extension Date {
    // MARK: - Thread-safe cached formatters per locale (für Month + Year)
    private static var monthYearFormatters: [String: DateFormatter] = [:]
    private static let monthYearQueue = DispatchQueue(label: "com.agil.date.monthYearQueue") //Eigener Thread

    private static func monthYearFormatter(for locale: Locale) -> DateFormatter {
        let id = locale.identifier
        return monthYearQueue.sync {
            if let f = monthYearFormatters[id] { return f }
            let f = DateFormatter()
            f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            f.locale = locale
            monthYearFormatters[id] = f
            return f
        }
    }

    /// Beispiel: "November 2025" (lokalisiert)
    func monthYearString(locale: Locale = .current) -> String {
        if #available(iOS 15.0, *) {
            return formatted(.dateTime.month(.wide).year())
        } else {
            return Self.monthYearFormatter(for: locale).string(from: self)
        }
    }

    // MARK: - Andere Formatierungen
    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EE, dd.MM.yyyy"
        f.locale = Locale(identifier: "deDE")
        return f.string(from: self)
    }

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: self) + " Uhr"
    }

    // key formatter (stabil, POSIX)
    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "enUSPOSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    func formatDateKey() -> String {
        Self.keyFormatter.string(from: self)
    }

    // Kurzer Wochentags‑Formatter (z.B. "Mo", "Di")
    static let shortDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: "deDE")
        return f
    }()

    // MARK: - Calendar Helpers
    func isSameDay(as other: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }

    func startOfWeek(using calendar: Calendar = .current) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: comps) ?? self
    }

    func addingDays( days: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }

    func daysOfWeek(startingAt start: Date? = nil, calendar: Calendar = .current) -> [Date] {
        let startDate = (start ?? self.startOfWeek(using: calendar))
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
    }
}

extension Date {
    func daysInMonth() -> [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: self)!
        
        return range.compactMap { day in
            var components = calendar.dateComponents([.year, .month], from: self)
            components.day = day
            return calendar.date(from: components)
        }
    }
    
    func firstDayOfMonth() -> Date {
           let calendar = Calendar.current
           let components = calendar.dateComponents([.year, .month], from: self)
           return calendar.date(from: components) ?? self
       }
}
