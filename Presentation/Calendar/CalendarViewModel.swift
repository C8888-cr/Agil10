import Foundation
import SwiftUI

@MainActor
final class CalendarViewModel: ObservableObject {

    // MARK: - Dependencies
    private let session: SessionManager
    private let calendar: Calendar = .current

    // MARK: - Published
    @Published var selectedDate: Date
    @Published private(set) var currentWeekOffset: Int = 0

    // MARK: - Private
    private let anchorDate: Date
    private(set) weak var progressViewModel: ProgressViewModel?

    // MARK: - Init
    init(
        selectedDate: Date = Date(),
        progressViewModel: ProgressViewModel,
        session: SessionManager
    ) {
        self.selectedDate = selectedDate
        self.anchorDate = selectedDate
        self.progressViewModel = progressViewModel
        self.session = session
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

        if let progressVM = progressViewModel,
           let user = session.currentUser {
            progressVM.selectedDate = date
            progressVM.loadToday(for: user, date: date)
        }

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
        guard let progressVM = progressViewModel else { return false }
        return !progressVM.schedulesFor(date: date).isEmpty
    }

    func scheduleCount(for date: Date) -> Int {
        guard let progressVM = progressViewModel else { return 0 }
        return progressVM.schedulesFor(date: date).count
    }

    func completionPercentage(for date: Date) -> Double {
        guard let progressVM = progressViewModel else { return 0.0 }
        let schedules = progressVM.schedulesFor(date: date)
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

    // MARK: - Helpers
    private func startOfWeek(for date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    private func updateSelectedDateIfNeeded() {
        if !currentWeekDays.contains(where: { calendar.isDate($0, inSameDayAs: selectedDate) }) {
            selectedDate = currentWeekStart

            if let progressVM = progressViewModel,
               let user = session.currentUser { 
                progressVM.selectedDate = selectedDate
                progressVM.loadToday(for: user, date: selectedDate)
            }
        }
    }
}
