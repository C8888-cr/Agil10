import Foundation
import SwiftUI
import SwiftData


@MainActor
final class CalendarViewModel: ObservableObject {
 
    private let calendar: Calendar = .current
    

    @Published var selectedDate: Date
    @Published private(set) var currentWeekOffset: Int = 0

    // Anchor-Date: die Referenzwoche, von der aus Offset gerechnet wird
    private let anchorDate: Date

    
    weak var progressViewModel: ProgressViewModel?
    init(selectedDate: Date = Date()) {
           self.selectedDate = selectedDate
           self.anchorDate = selectedDate
       }
    
    // ✅ AuthService aus AppDependencies holen
       private var authService: AuthService {
           AppDependencies.shared.authService
       }
       
       // ✅ Dann currentUser daraus holen
       private var currentUser: User? {
           authService.currentUser
       }
  
    // Startdatum der aktuell angezeigten Woche (AnchorStart + Offset)
    private var anchorWeekStart: Date {
        startOfWeek(for: anchorDate)
    }

    var currentWeekStart: Date {
        calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: anchorWeekStart) ?? anchorWeekStart
    }

    
    //alter Code von agil5
    var currentWeekDays: [Date] {
        (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: currentWeekStart)
        }
    }
    // 7 Tage der aktuellen Woche // neuer Code
  /*  var currentWeekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: currentWeekStart) }
    }
*/
    // MARK: - Aktionen
    func previousWeek() {
        withAnimation { currentWeekOffset -= 1 }
    }

    func nextWeek() {
        withAnimation { currentWeekOffset += 1 }
    }

    /// Wählt ein Datum aus und verschiebt die Ansicht so, dass dessen Woche angezeigt wird
    func select(date: Date) {
        selectedDate = date
        
        // ✅ ProgressViewModel informieren
           if let progressVM = progressViewModel,
              let user = AppDependencies.shared.authService.currentUser {
               progressVM.selectedDate = date
               progressVM.loadToday(for: user, date: date)
           }
           
        let selectedWeekStart = startOfWeek(for: date)
        
        // Abstand in Tagen berechnen und durch 7 teilen → stabiler
        let daysDiff = calendar.dateComponents([.day], from: anchorWeekStart, to: selectedWeekStart).day ?? 0
        currentWeekOffset = daysDiff / 7
    }

    /// Schnell zur heutigen Woche springen
    func goToToday() {
        let today = Date()
        select(date: today)
    }

    /// Optional: direkt zu einem Datum springen (alias)
    func goToDate( date: Date) {
        select(date: date)
    }
    
    /// Wenn selectedDate nicht mehr in currentWeekDays liegt,
       /// auf ersten Tag der aktuellen Woche setzen
       private func updateSelectedDateIfNeeded() {
           if !currentWeekDays.contains(where: { calendar.isDate($0, inSameDayAs: selectedDate) }) {
               selectedDate = currentWeekStart
               
               // ✅ ProgressViewModel informieren
               if let progressVM = progressViewModel,
                  let user = AppDependencies.shared.authService.currentUser {
                   progressVM.selectedDate = selectedDate
                   progressVM.loadToday(for: user, date: selectedDate)
               }
           }
       }
    
  

    // MARK: - Helpers
    private func startOfWeek(for date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }
    // MARK: - Schedule Info (✅ NEU - ersetzt getMonthWithPlans)
      
      /// Prüft ob ein Datum Schedules hat (via ProgressViewModel)
      func hasSchedules(on date: Date) -> Bool {
          guard let progressVM = progressViewModel else { return false }
          return !progressVM.schedulesFor(date: date).isEmpty
      }
      
      /// Anzahl der Schedules für ein Datum
      func scheduleCount(for date: Date) -> Int {
          guard let progressVM = progressViewModel else { return 0 }
          return progressVM.schedulesFor(date: date).count
      }
      
      /// Completion Status für ein Datum (0.0 ... 1.0)
      func completionPercentage(for date: Date) -> Double {
          guard let progressVM = progressViewModel else { return 0.0 }
          let schedules = progressVM.schedulesFor(date: date)
          guard !schedules.isEmpty else { return 0.0 }
          
          let completed = schedules.filter { $0.isCompleted }.count
          return Double(completed) / Double(schedules.count)
      }
      
      /// Alle Tage des aktuellen Monats mit Infos
      func currentMonthDays() -> [(date: Date, hasSchedules: Bool, completion: Double)] {
          let days = Date().daysInMonth()
          return days.map { date in
              (
                  date: date,
                  hasSchedules: hasSchedules(on: date),
                  completion: completionPercentage(for: date)
              )
          }
      }
    
}
