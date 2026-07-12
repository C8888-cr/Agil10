//
//  CompactWeekView.swift
//  Agil
//
//  Created by Christiane Roth on 23.11.25.
//

import SwiftUI
import SwiftData
import AgilCore

struct CompactWeekView: View {
@EnvironmentObject var appointmentViewModel: AppointmentViewModel
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var themeManager: ThemeManager
    // ✅ @Query für Termine
       @Query(sort: \Appointment.date) private var allAppointments: [Appointment]
       
       // ✅ Gefilterte Termine
       private var appointments: [Appointment] {
           allAppointments.filter { $0.date > Date().addingTimeInterval(-86400) }
       }
    var body: some View {
        VStack(spacing: 12) {
            
            HStack {
                Button(action: { calendarViewModel.previousWeek() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                Text(calendarViewModel.selectedDate.monthYearString())
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                Button(action: { calendarViewModel.nextWeek() }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.vertical, 8)
   
                     
                     
            HStack {
                ForEach(Array(calendarViewModel.currentWeekDays.enumerated()), id: \.offset) { index, date in
                                 CompactDayCell(
                                     date: date,
                                     isSelected: date.isSameDay(as: calendarViewModel.selectedDate),
                                     isToday: date.isSameDay(as: Date()),
                                     hasAppointment: appointmentViewModel.hasAppointment(on: date, in: appointments)
                                 
                 //       hasExercises: trainingViewModel.hasExercises(on: date),
                 //       exerciseProgress: trainingViewModel.progressForDate(date)
                    )
                    .onTapGesture {
                      //  withAnimation(.easeInOut(duration: 0.2)) {
                            calendarViewModel.select(date: date)
                  //      }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

/*
#Preview {
    let previewContainer = try! ModelContainer(
        for: VideoSchedule.self, Appointment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let context = previewContainer.mainContext
       let authService = AuthService(authServiceProtocol: MockAuthService(modelContext: context))
    let repository = VideoScheduleRepository(modelContext: context)
      let progressVM = ProgressViewModel(authService: authService, repository: repository)
       let calVM = CalendarViewModel(progressViewModel: progressVM, authService: authService)
       let apptVM = PreviewHelper.createAppointmentViewModel()
    

    
    CompactWeekView()
        .environmentObject(calVM)
        .environmentObject(apptVM)
        .modelContainer(previewContainer)
}
*/
