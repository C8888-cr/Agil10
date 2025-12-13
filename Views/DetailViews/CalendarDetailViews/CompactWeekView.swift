//
//  CompactWeekView.swift
//  Agil
//
//  Created by Christiane Roth on 23.11.25.
//

import SwiftUI

struct CompactWeekView: View {
@EnvironmentObject var appointmentViewModel: AppointmentViewModel
    @EnvironmentObject var calendarViewModel: CalendarViewModel

    var body: some View {
        VStack(spacing: 12) {
            
            HStack {
                Button(action: { calendarViewModel.previousWeek() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                Text(calendarViewModel.currentWeekStart.monthYearString())
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                Button(action: { calendarViewModel.nextWeek() }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 8) {
                ForEach(Array(calendarViewModel.currentWeekDays.enumerated()), id: \.offset) { index, date in
                                 CompactDayCell(
                                     date: date,
                                     isSelected: date.isSameDay(as: calendarViewModel.selectedDate),
                                     isToday: date.isSameDay(as: Date()),
                                     hasAppointment: appointmentViewModel.hasAppointment(on: date)
                                 
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
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}
#Preview {
    let calVM = CalendarViewModel()
    let apptVM = PreviewHelper.createAppointmentViewModel()
    calVM.selectedDate = Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 23))!
    return VStack {
        CompactWeekView()
            .environmentObject(calVM)
            .environmentObject(apptVM)
    }
}
