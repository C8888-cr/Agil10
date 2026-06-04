//
//  TimeRangeMode.swift
//  Agil10.0
//
//  Created by Christiane Roth on 02.06.26.
//


//
//  TimeRangeSelector.swift
//  Agil
//
//  Wiederverwendbare Zeitraum-Komponente (Apple-Health-Style).
//  Zeigt 7T / 1M / 1J nebeneinander + Pfeil-Navigation vor/zurück.
//  Gibt nach außen: aktiven Bereich (start/end) + Granularität für Charts.
//

import SwiftUI

// MARK: - Model

enum TimeRangeMode: String, CaseIterable {
    case week  = "7T"
    case month = "1M"
    case year  = "1J"

    var displayName: String { rawValue }

    var granularity: MetricGranularity {
        switch self {
        case .week:  return .day
        case .month: return .day
        case .year:  return .month
        }
    }

    /// Berechnet Start + End für einen gegebenen Offset (0 = aktuell, -1 = zurück).
    func range(offset: Int) -> (start: Date, end: Date) {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current   // ← explizit lokale Zeitzone
        let now = Date()
        switch self {
        case .week:
            let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start
                ?? cal.startOfDay(for: now)
            let start = cal.date(byAdding: .weekOfYear, value: offset, to: weekStart)!
            let end   = cal.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, end)
        case .month:
            let base  = cal.dateInterval(of: .month, for: now)!.start
            let start = cal.date(byAdding: .month, value: offset, to: base)!
            let end   = cal.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .year:
            let base  = cal.dateInterval(of: .year, for: now)!.start
            let start = cal.date(byAdding: .year, value: offset, to: base)!
            let end   = cal.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        }
    }

    /// Lesbares Label für den aktuellen Zeitraum.
    func label(offset: Int) -> String {
        let (start, end) = range(offset: offset)
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        switch self {
        case .week:
            formatter.dateFormat = "d. MMM"
            let endDisplay = cal.date(byAdding: .day, value: -1, to: end)!
            return "\(formatter.string(from: start)) – \(formatter.string(from: endDisplay))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: start)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: start)
        }
    }
    func canGoForward(offset: Int) -> Bool {
        offset < 0
    }
}

// MARK: - View

struct TimeRangeSelector: View {
    @Binding var mode: TimeRangeMode
    @Binding var offset: Int
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 8) {
            modePicker
            navigationRow
        }
    }

    // MARK: - Mode Tabs (7T / 1M / 1J)
    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRangeMode.allCases, id: \.self) { m in
                Button {
                    if mode != m {
                        mode = m
                        offset = 0
                    }
                } label: {
                    Text(m.displayName)
                        .font(.subheadline.weight(mode == m ? .semibold : .regular))
                        .foregroundStyle(mode == m ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            mode == m
                            ? RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(.tertiarySystemGroupedBackground))
                            : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Pfeil-Navigation
    private var navigationRow: some View {
        HStack {
            Button {
                offset -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(themeManager.currentTheme.accentColor)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(mode.label(offset: offset))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .animation(.none, value: offset)

            Spacer()

            Button {
                offset += 1
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        mode.canGoForward(offset: offset)
                        ? themeManager.currentTheme.accentColor
                        : Color.secondary.opacity(0.3)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!mode.canGoForward(offset: offset))
        }
    }
}
