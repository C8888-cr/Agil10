import Foundation
import SwiftUI

@MainActor
final class CalendarViewModel: ObservableObject {

    // MARK: - Dependencies
    private let session: SessionManager
    private let getSchedulesUseCase: GetSchedulesForDateUseCase
    private let calendar: Calendar = .current

    // MARK: - Published
    @Published var selectedDate: Date
    @Published private(set) var currentWeekOffset: Int = 0
    @Published var currentMonth: Date = Date()

    // MARK: - Private
    private let anchorDate: Date

    // MARK: - Init
    init(
        selectedDate: Date = Date(),
        session: SessionManager,
        getSchedulesUseCase: GetSchedulesForDateUseCase
    ) {
        self.selectedDate = selectedDate
        self.anchorDate = selectedDate
        self.session = session
        self.getSchedulesUseCase = getSchedulesUseCase
    }

    // MARK: - Week Navigation
    private var anchorWeekStart: Date {
        startOfWeek(for: anchorDate)
    }

    var currentWeekStart: Date {
        calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: anchorWeekStart) ?? anchorWeekStart
    }

    var currentWeekDays: [Date] {
        (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: currentWeekStart)
        }
    }

    // MARK: - Actions
    func previousWeek() {
        withAnimation { currentWeekOffset -= 1 }
    }

    func nextWeek() {
        withAnimation { currentWeekOffset += 1 }
    }

    func select(date: Date) {
        selectedDate = date
        let selectedWeekStart = startOfWeek(for: date)
        let daysDiff = calendar.dateComponents([.day], from: anchorWeekStart, to: selectedWeekStart).day ?? 0
        currentWeekOffset = daysDiff / 7
    }

    func goToToday() {
        select(date: Date())
    }

    func goToDate(date: Date) {
        select(date: date)
    }

    // MARK: - Schedule Info
    func hasSchedules(on date: Date) -> Bool {
        guard let userId = session.currentUser?.id else { return false }
        let schedules = (try? getSchedulesUseCase.execute(date: date, userId: userId)) ?? []
        return !schedules.isEmpty
    }

    func scheduleCount(for date: Date) -> Int {
        guard let userId = session.currentUser?.id else { return 0 }
        return (try? getSchedulesUseCase.execute(date: date, userId: userId))?.count ?? 0
    }

    func completionPercentage(for date: Date) -> Double {
        guard let userId = session.currentUser?.id else { return 0.0 }
        let schedules = (try? getSchedulesUseCase.execute(date: date, userId: userId)) ?? []
        guard !schedules.isEmpty else { return 0.0 }
        let completed = schedules.filter { $0.isCompleted }.count
        return Double(completed) / Double(schedules.count)
    }

    func currentMonthDays() -> [(date: Date, hasSchedules: Bool, completion: Double)] {
        Date().daysInMonth().map { date in
            (
                date: date,
                hasSchedules: hasSchedules(on: date),
                completion: completionPercentage(for: date)
            )
        }
    }
    
    

    func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }

    func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }

    func daysInMonth(for month: Date) -> [(date: Date, hasSchedules: Bool, hasAppointments: Bool, completion: Double)] {
        month.daysInMonth().map { date in
            (
                date: date,
                hasSchedules: hasSchedules(on: date),
                hasAppointments: false, // ← kommt von außen via appointments Array
                completion: completionPercentage(for: date)
            )
        }
    }

    func monthTitle(for month: Date) -> String {
        month.formatted(.dateTime.month(.wide).year())
    }

    var isCurrentMonth: Bool {
        calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Helpers
    private func startOfWeek(for date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }
}
