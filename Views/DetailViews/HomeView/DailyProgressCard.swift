//
//  DailyProgressCard.swift
//  Agil
//
//  Created by Christiane Roth on 26.11.25.
//


 import SwiftUI
import SwiftData


struct DailyProgressCard: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var weeklySettings: WeeklySettings
    @EnvironmentObject var appointmentViewModel: AppointmentViewModel
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    
    // ✅ @Query für Termine
       @Query(sort: \Appointment.date) private var allAppointments: [Appointment]
       
       // ✅ Gefilterte Termine (nur zukünftige)
       private var appointments: [Appointment] {
           allAppointments.filter { $0.date > Date().addingTimeInterval(-86400) }
       }
    
    // ✅ Berechne Ziel aus ProgressVM-Werten
    // ✅ KORRIGIERT: Direkt aus Settings holen!
    private var todaysTargetMinutes: Int {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: Date())
        let todayDayOfWeek = (rawWeekday - firstWeekday + 7) % 7
        
        return settingsVM.preferences.getGoalFor(dayOfWeek: todayDayOfWeek)?.targetMinutes ?? 30
    }
    // ✅ NEU: Separate Computed Properties
    private var completedMinutes: Int {
        progressVM.completedMinutes
    }
    
    private var remainingMinutes: Int {
        max(0, todaysTargetMinutes - completedMinutes)
    }
    
    private var dailyProgressValue: Double {
        guard todaysTargetMinutes > 0 else { return 0 }
        return min(1.0, Double(completedMinutes) / Double(todaysTargetMinutes))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heutiges Training")
                        .font(.headline)
                    
                    // ✅ DYNAMISCH - verwendet die computed properties!
                    Text("\(todaysTargetMinutes) Min Ziel • \(remainingMinutes) Min verbleibend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: dailyProgressValue)  // ✅ GEÄNDERT!
                        .stroke(
                            LinearGradient(
                                colors: [.accent, .accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progressVM.dailyProgress)
                    
                    Text("\(Int(dailyProgressValue * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.accent)
                }
            }
            
            Divider()
            
            
            if let nextAppointment = appointmentViewModel.nextAppointment(from: appointments) {
                CompactAppointmentView(appointment: nextAppointment)
            }
          
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}



 // MARK: - Compact Appointment View
 struct CompactAppointmentView: View {
     let appointment: Appointment
     
     var body: some View {
         VStack(alignment: .leading, spacing: 4) {
             HStack(spacing: 4) {
                 Image(systemName: "calendar")
                     .font(.caption)
                     .foregroundColor(.accent)
                 Text("Nächster Termin")
                     .font(.caption)
                     .foregroundColor(.secondary)
             }
             HStack(spacing: 12) {
                 Text(appointment.timeString)
                     .font(.title3)
                     .fontWeight(.semibold)
                     .foregroundColor(.primary)

                 VStack(alignment: .leading, spacing: 2) {
                     Text(appointment.therapist)
                         .font(.caption)
                         .foregroundColor(.secondary)
                     Text(appointment.locationName ?? "")
                         .font(.caption)
                         .foregroundColor(.secondary)
                     
                     // ✅ Notizen optional
                                       if let notes = appointment.notes, !notes.isEmpty {
                                           Text(notes)
                                               .font(.caption2)
                                               .foregroundColor(.secondary)
                                               .italic()
                                       }
                 }
                 Spacer()
             }
         }
         .frame(maxWidth: .infinity, alignment: .leading)
     }
 }
 
#Preview {
    let deps = AppDependencies.shared  // ✅ Nimm einfach die echte Dependency!
    
    DailyProgressCard()
      //  .environmentObject(deps.trainingData)
        .environmentObject(WeeklySettings())
        .environmentObject(deps.progressViewModel)
        .environmentObject(deps.appointmentViewModel)
        .environmentObject(deps.settingsViewModel)
        .modelContainer(deps.modelContainer)
}
#Preview("CompactAppointmentView") {
    let appointment = Appointment(
        id: UUID(),
        date: Date().addingTimeInterval(86400 * 3),
        therapist: "Dr. Schmidt",
        locationName: "Praxis Schmidt",
        locationAddress: "Musterstr. 1, 10115 Berlin",
        locationLatitude: 52.52,
        locationLongitude: 13.40,
        notes: "Physiotherapie Schulter",
        emailUID: "test@example.com",
        status: .confirmed,
        userId: UUID(),
        therapistId: UUID(),
        praxisId: UUID()
    )
    
    return CompactAppointmentView(appointment: appointment)
        .padding()
        .background(Color(.systemGray6))
}
