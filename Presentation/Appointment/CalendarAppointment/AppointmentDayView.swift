//
//  AppointmentDayView.swift
//  Agil10.0
//
//  Tagesansicht mit Stunden-Raster und Wochen-Leiste oben.
//  Wird von AppointmentView orchestriert.
//

import SwiftUI
import SwiftData

struct AppointmentDayView: View {

    @ObservedObject var viewModel: AppointmentPlannerViewModel
    @State private var displayedDay: Date
    @State private var prefilledSlot: SlotItem? = nil
    @State private var appointmentToEdit: Appointment? = nil
    @State private var appointmentToDelete: Appointment? = nil
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var appointmentViewModel: AppointmentViewModel

    /// Callback: zurück zur MonthView (mit aktuellem Tag als Anker)
    var onBackToMonth: (Date) -> Void
    /// Callback: ganz raus zur AppointmentView
    var onCloseAll: () -> Void

    @Query private var allAppointments: [Appointment]

    private let hourHeight: CGFloat = 60
    private let startHour: Int = 6
    private let endHour: Int = 23

    init(
        viewModel: AppointmentPlannerViewModel,
        initialDay: Date,
        onBackToMonth: @escaping (Date) -> Void,
        onCloseAll: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onBackToMonth = onBackToMonth
        self.onCloseAll = onCloseAll
        _displayedDay = State(initialValue: Calendar.current.startOfDay(for: initialDay))
    }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEEE, d. MMMM"
        return f
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "MMMM"
        return f.string(from: displayedDay)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                weekStrip

                Divider()

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

                ScrollView {
                    hourGrid
                        .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        guard abs(horizontal) > abs(vertical) * 1.5,
                              abs(horizontal) > 50 else { return }

                        let cal = Calendar.current
                        let direction = horizontal < 0 ? 7 : -7
                        if let newDay = cal.date(byAdding: .day, value: direction, to: displayedDay) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                displayedDay = cal.startOfDay(for: newDay)
                            }
                        }
                    }
            )
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // < Monatsname → zurück zu MonthView
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onBackToMonth(displayedDay)
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text(monthLabel)
                                .font(.body.weight(.semibold))
                        }
                        .foregroundStyle(themeManager.currentTheme.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .glassEffect(in: Capsule())
                    }
                }

                // X → AppointmentView
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onCloseAll()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(themeManager.currentTheme.accentColor)
                            .frame(width: 32, height: 32)
                            .glassEffect(in: Circle())
                    }
                }
            }
            .task {
                await loadEventsForDisplayedWeek()
            }
            .onChange(of: displayedDay) { _, _ in
                Task { await loadEventsForDisplayedWeek() }
            }
            .sheet(item: $prefilledSlot, onDismiss: {
                Task { await loadEventsForDisplayedWeek() }
            }) { slot in
                ManualAppointmentEntryView(prefilledDate: slot.date)
            }
            .sheet(item: $appointmentToEdit, onDismiss: {
                Task { await loadEventsForDisplayedWeek() }
            }) { appt in
                ManualAppointmentEntryView(appointmentToEdit: appt)
            }
            .confirmationDialog(
                "Termin löschen?",
                isPresented: Binding(
                    get: { appointmentToDelete != nil },
                    set: { if !$0 { appointmentToDelete = nil } }
                ),
                presenting: appointmentToDelete
            ) { appt in
                Button("Löschen", role: .destructive) {
                    Task {
                        await appointmentViewModel.deleteAppointment(appt)
                        appointmentToDelete = nil
                        await loadEventsForDisplayedWeek()
                    }
                }
                Button("Abbrechen", role: .cancel) {
                    appointmentToDelete = nil
                }
            } message: { _ in
                Text("Möchtest du diesen Termin wirklich löschen?")
            }
        }
    }

    // MARK: - Wochen-Leiste

    private var weekStrip: some View {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: displayedDay)
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

            Rectangle()
                .fill(hasEvents ? Color("Blau") : Color.clear)
                .frame(width: 12, height: 2)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    // MARK: - Stunden-Raster

    private var hourGrid: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(startHour...endHour, id: \.self) { hour in
                    hourRow(hour: hour)
                }
            }

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

                Color.clear
                    .frame(height: hourHeight - 1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        prefilledSlot = SlotItem(id: makeDate(hour: hour, minute: 0))
                    }
            }
        }
        .frame(height: hourHeight)
    }

    private func eventBlock(_ event: CalendarEvent) -> some View {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: displayedDay)
        let baseOffset = CGFloat(startHour) * hourHeight

        let eventStartOnDay = max(event.start, cal.date(byAdding: .hour, value: startHour, to: startOfDay) ?? event.start)
        let eventEndOnDay = min(event.end, cal.date(byAdding: .hour, value: endHour + 1, to: startOfDay) ?? event.end)

        let startMinutes = eventStartOnDay.timeIntervalSince(startOfDay) / 60
        let endMinutes = eventEndOnDay.timeIntervalSince(startOfDay) / 60

        let topOffset = CGFloat(startMinutes) * (hourHeight / 60) - baseOffset
        let height = max(20, CGFloat(endMinutes - startMinutes) * (hourHeight / 60))

        let color = Color("Blau")
        let agilAppt = agilAppointment(for: event)

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
        .padding(.leading, 52)
        .padding(.trailing, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if let appt = agilAppt {
                appointmentToEdit = appt
            }
        }
        .contextMenu {
            if let appt = agilAppt {
                Button(role: .destructive) {
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    appointmentToDelete = appt
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
        }
        .offset(y: topOffset)
    }

    // MARK: - Helpers

    private func agilAppointment(for event: CalendarEvent) -> Appointment? {
        guard let userId = session.currentUser?.id else { return nil }
        return allAppointments.first { appt in
            appt.userId == userId
            && appt.calendarEventIdentifier == event.id
        }
    }

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

private struct SlotItem: Identifiable {
    let id: Date
    var date: Date { id }
}
