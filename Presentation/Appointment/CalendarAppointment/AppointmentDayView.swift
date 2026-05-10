//
//  AppointmentDayView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  AppointmentDayView.swift
//  Agil10.0
//
//  Tagesansicht mit Stunden-Raster und Wochen-Leiste oben.
//  Tap auf freien Slot → ManualAppointmentEntryView mit vorausgefülltem Datum.
//

import SwiftUI

struct AppointmentDayView: View {

    @ObservedObject var viewModel: AppointmentPlannerViewModel
    @State private var displayedDay: Date
    @State private var prefilledSlot: Date? = nil
    @EnvironmentObject var themeManager: ThemeManager

    private let hourHeight: CGFloat = 60
    private let startHour: Int = 6      // Tag startet bei 6 Uhr
    private let endHour: Int = 23       // Tag endet bei 23 Uhr

    init(viewModel: AppointmentPlannerViewModel, initialDay: Date) {
        self.viewModel = viewModel
        _displayedDay = State(initialValue: Calendar.current.startOfDay(for: initialDay))
    }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEEE, d. MMMM"
        return f
    }

    var body: some View {
        VStack(spacing: 0) {
            // Wochen-Leiste oben
            weekStrip

            Divider()

            // Tagesname
            HStack {
                Text(dayFormatter.string(from: displayedDay))
                    .font(.headline)
                Spacer()
                if !Calendar.current.isDateInToday(displayedDay) {
                    Button("Heute") {
                        displayedDay = Calendar.current.startOfDay(for: Date())
                    }
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.accentColor)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Stunden-Raster
            ScrollView {
                hourGrid
                    .padding(.horizontal)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadEventsForDisplayedWeek()
        }
        .onChange(of: displayedDay) { _, _ in
            Task { await loadEventsForDisplayedWeek() }
        }
        .sheet(item: $prefilledSlot, onDismiss: {
            Task { await loadEventsForDisplayedWeek() }
        }) { slot in
            ManualAppointmentEntryView(prefilledDate: slot)
        }
    }

    // MARK: - Wochen-Leiste

    private var weekStrip: some View {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: displayedDay)
        // Montag als Wochenstart
        let mondayOffset = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -mondayOffset, to: displayedDay) ?? displayedDay
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }

        return HStack(spacing: 4) {
            ForEach(days, id: \.self) { day in
                weekDayCell(day)
                    .onTapGesture {
                        displayedDay = cal.startOfDay(for: day)
                    }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private func weekDayCell(_ day: Date) -> some View {
        let cal = Calendar.current
        let isSelected = cal.isDate(day, inSameDayAs: displayedDay)
        let isToday = cal.isDateInToday(day)
        let weekdayShort = day.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "de_DE")))
        let dayNumber = cal.component(.day, from: day)
        let hasEvents = !viewModel.events(on: day).isEmpty

        return VStack(spacing: 4) {
            Text(weekdayShort)
                .font(.caption2)
                .foregroundStyle(.secondary)

            ZStack {
                if isSelected {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor)
                        .frame(width: 32, height: 32)
                } else if isToday {
                    Circle()
                        .stroke(themeManager.currentTheme.accentColor, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }
                Text("\(dayNumber)")
                    .font(.body)
                    .fontWeight(isSelected || isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(height: 32)

            Circle()
                .fill(hasEvents ? themeManager.currentTheme.accentColor : .clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    // MARK: - Stunden-Raster

    private var hourGrid: some View {
        ZStack(alignment: .topLeading) {
            // Hintergrund: Stunden-Linien + Labels
            VStack(spacing: 0) {
                ForEach(startHour...endHour, id: \.self) { hour in
                    hourRow(hour: hour)
                }
            }

            // Events drüberlegen
            ForEach(viewModel.events(on: displayedDay).filter { !$0.isAllDay }) { event in
                eventBlock(event)
            }
        }
    }

    private func hourRow(hour: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(String(format: "%02d:00", hour))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)

                // Tappable Bereich (freier Slot)
                Color.clear
                    .frame(height: hourHeight - 1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        prefilledSlot = makeDate(hour: hour, minute: 0)
                    }
            }
        }
        .frame(height: hourHeight)
    }

    private func eventBlock(_ event: CalendarEvent) -> some View {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: displayedDay)
        let baseOffset = CGFloat(startHour) * hourHeight

        // Nur den Teil zeigen, der innerhalb unserer Stunden-Range liegt
        let eventStartOnDay = max(event.start, cal.date(byAdding: .hour, value: startHour, to: startOfDay) ?? event.start)
        let eventEndOnDay = min(event.end, cal.date(byAdding: .hour, value: endHour + 1, to: startOfDay) ?? event.end)

        let startMinutes = eventStartOnDay.timeIntervalSince(startOfDay) / 60
        let endMinutes = eventEndOnDay.timeIntervalSince(startOfDay) / 60

        let topOffset = CGFloat(startMinutes) * (hourHeight / 60) - baseOffset
        let height = max(20, CGFloat(endMinutes - startMinutes) * (hourHeight / 60))

        let color = Color(
            red: event.calendarColor.red,
            green: event.calendarColor.green,
            blue: event.calendarColor.blue
        )

        return HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text("\(event.start.formatted(.dateTime.hour().minute())) – \(event.end.formatted(.dateTime.hour().minute()))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height, alignment: .top)
        .background(color.opacity(0.15))
        .cornerRadius(6)
        .padding(.leading, 52)   // Platz für Stunden-Labels
        .padding(.trailing, 4)
        .offset(y: topOffset)
    }

    // MARK: - Helpers

    private func makeDate(hour: Int, minute: Int) -> Date {
        let cal = Calendar.current
        return cal.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: displayedDay
        ) ?? displayedDay
    }

    private func loadEventsForDisplayedWeek() async {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: displayedDay)
        let mondayOffset = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -mondayOffset, to: displayedDay) ?? displayedDay
        let weekStart = cal.startOfDay(for: monday)
        let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        await viewModel.loadEvents(from: weekStart, to: weekEnd)
    }
}

// Damit ein Date als Sheet-Identifier funktioniert
extension Date: Identifiable {
    public var id: Date { self }
}
