import Foundation
import SwiftUI
import SwiftData


@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var trainingData: TrainingData
    private let calendar: Calendar = .current
    

    @Published var selectedDate: Date
    @Published private(set) var currentWeekOffset: Int = 0

    // Anchor-Date: die Referenzwoche, von der aus Offset gerechnet wird
    private let anchorDate: Date
    
    // ✅ trainingData als optionaler Parameter (lazy init)
        init(
            selectedDate: Date = Date(),
            trainingData: TrainingData? = nil
        ) {
            self.selectedDate = selectedDate
            self.anchorDate = selectedDate
            
            // ✅ Lazy initialization oder von außen übergeben
            if let trainingData = trainingData {
                self.trainingData = trainingData
            } else {
                self.trainingData = TrainingData(weeklySettings: WeeklySettings())
            }
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
    
    //holt die Tage aus dem jeweiligen 
    func getMonthWithPlans() -> [(date: Date, dayName: String, dayPlan: DayPlan?)] {
          let currentMonth = Date().daysInMonth()
          return currentMonth.map { day in
              let dayName = day.formatted(.dateTime.weekday(.abbreviated))
              let dayPlan = trainingData.weekPlan.first(where: { $0.dayName == dayName })
              return (date: day, dayName: dayName, dayPlan: dayPlan)
          }
      }

    // MARK: - Helpers
    private func startOfWeek(for date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }
}
