//
//  AppointmentDayView.swift
//  Agil10.0
//
//  Tagesansicht mit Stunden-Raster und Wochen-Leiste oben.
//  Wird von AppointmentView orchestriert.
//

import SwiftUI
import SwiftData
import AgilCore

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
    private let startHour: Int = 0
    private let endHour: Int = 23

    private var allDayEvents: [CalendarEvent] {
        viewModel.events(on: displayedDay).filter { $0.isAllDay }
    }

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

                dayHeader

                allDayStrip

                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        hourGrid
                            .padding(.horizontal)
                    }
                    .onAppear {
                        let cal = Calendar.current
                        let targetHour: Int = cal.isDateInToday(displayedDay)
                            ? cal.component(.hour, from: Date())
                            : 8
                        DispatchQueue.main.async {
                            withAnimation(.none) {
                                proxy.scrollTo("hour-\(targetHour)", anchor: .top)
                            }
                        }
                    }
                    .onChange(of: displayedDay) { _, newDay in
                        let cal = Calendar.current
                        let targetHour: Int = cal.isDateInToday(newDay)
                            ? cal.component(.hour, from: Date())
                            : 8
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo("hour-\(targetHour)", anchor: .top)
                        }
                    }
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
            .overlay(alignment: .bottomLeading) {
                if !Calendar.current.isDateInToday(displayedDay) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            displayedDay = Calendar.current.startOfDay(for: Date())
                        }
                    } label: {
                        Text("Heute")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(themeManager.currentTheme.accentColor)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .glassEffect(in: Capsule())
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                await viewModel.loadEventsIfNeeded(around: displayedDay)
            }
            .onChange(of: displayedDay) { _, _ in
                Task { await viewModel.loadEventsIfNeeded(around: displayedDay) }
            }
            .sheet(item: $prefilledSlot, onDismiss: {
                Task { await viewModel.refreshMonth(containing: displayedDay) }
            }) { slot in
                ManualAppointmentEntryView(prefilledDate: slot.date)
            }
            .sheet(item: $appointmentToEdit, onDismiss: {
                Task { await viewModel.refreshMonth(containing: displayedDay) }
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
                        await viewModel.refreshMonth(containing: displayedDay)
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

    // MARK: - Tages-Header

    private var dayHeader: some View {
        Text(dayFormatter.string(from: displayedDay).capitalized)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
    }

    // MARK: - Ganztägig-Leiste

    @ViewBuilder
    private var allDayStrip: some View {
        if !allDayEvents.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Text("Ganztägig")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(allDayEvents) { event in
                        Text(event.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color("Blau").opacity(0.18))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(.systemBackground))
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
        .id("hour-\(hour)")
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

        let agilAppt = agilAppointment(for: event)
                let isCancelled = agilAppt?.status == .cancelled
                let color = isCancelled ? Color.red : Color("Blau")
        let displayTitle: String = {
                    guard let appt = agilAppt, appt.status == .cancelled else { return event.title }
                    return AppointmentCalendarTitleBuilder.build(for: appt)
                }()
        let rawHeight = CGFloat(endMinutes - startMinutes) * (hourHeight / 60)
        let height: CGFloat = max(hourHeight, rawHeight)

        return HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                Text(timeRangeText(event: event, agilAppt: agilAppt))
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

    /// Zeigt die echte Termindauer an, nicht die ggf. gestreckte Apple-Event-Dauer.
    private func timeRangeText(event: CalendarEvent, agilAppt: Appointment?) -> String {
        let start = event.start.formatted(.dateTime.hour().minute())
        let endDate: Date
        if let appt = agilAppt {
            endDate = event.start.addingTimeInterval(TimeInterval(appt.durationMinutes * 60))
        } else {
            endDate = event.end
        }
        let end = endDate.formatted(.dateTime.hour().minute())
        return "\(start) – \(end)"
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
}

private struct SlotItem: Identifiable {
    let id: Date
    var date: Date { id }
}
