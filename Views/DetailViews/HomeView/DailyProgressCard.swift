//
//  DailyProgressCard.swift
//  Agil
//
//  Created by Christiane Roth on 26.11.25.
//


 import SwiftUI
import SwiftData


 struct DailyProgressCard: View {

  
     @EnvironmentObject var weeklySettings: WeeklySettings
     @EnvironmentObject var appointmentViewModel: AppointmentViewModel
     @EnvironmentObject var progressVM: ProgressViewModel
     
     // ✅ Berechne Ziel aus ProgressVM-Werten
     private var todaysTargetMinutes: Int {
         progressVM.targetMinutes
     }

     
     var body: some View {
         VStack(spacing: 16) {
             // Header
             HStack {
                 VStack(alignment: .leading, spacing: 4) {
                     Text("Heutiges Training")
                         .font(.headline)
                     
    // ✅ DYNAMISCH: "30 Min Ziel • 15 Min verbleibend"
                     Text("\(todaysTargetMinutes) Min Ziel • \(progressVM.remainingMinutes) Min verbleibend")
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
                         .trim(from: 0, to: progressVM.dailyProgress)
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
                     
                     Text("\(Int(progressVM.dailyProgress * 100))%")
                         .font(.caption)
                         .fontWeight(.bold)
                         .foregroundColor(.accent)
                 }
             }
             
             // Exercise Type Breakdown
             if !progressVM.todaysSchedules.isEmpty {
                  Divider()
                 
                 VStack(spacing: 8) {
                     Text("Übungsarten")
                         .font(.caption)
                         .foregroundColor(.secondary)
                         .frame(maxWidth: .infinity, alignment: .leading)
                     
                     LazyVGrid(columns: [
                         GridItem(.flexible()),
                         GridItem(.flexible())
                     ], spacing: 8) {
                         ForEach(getExerciseTypeSummary(), id: \.type) { summary in
                             ExerciseTypeBadge(
                                 type: summary.type,
                                 count: summary.count,
                                 duration: summary.duration)
                         }
                     }
                 }
             }
         }
         .padding()
         .background(
             RoundedRectangle(cornerRadius: 16)
                 .fill(Color(.systemBackground))
                 .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
         )
     }
     
     private func getExerciseTypeSummary() -> [(type: ExerciseCategory, count: Int, duration: Int)] {
         let videos = progressVM.todaysSchedules.compactMap { $0.video }
         let grouped = Dictionary(grouping: videos) { $0.category }
         
         return grouped.map { type, videos in
             (
                 type: type,
                 count: videos.count,
                 duration: videos.reduce(0) { $0 + $1.durationMinutes }
             )
         }.sorted { $0.duration > $1.duration }
     }
 }
 // MARK: - Compact Top Section (für Dashboard)
 struct CompactTopSection: View {
     @EnvironmentObject var progressVM: ProgressViewModel  // ✅ GEÄNDERT!
     @EnvironmentObject var appointmentViewModel: AppointmentViewModel
     
     var body: some View {
         HStack(spacing: 16) {
             // Daily Progress (kompakt)
             CompactProgressView()
             
             // Termin
             if let nextAppointment = appointmentViewModel.nextAppointment {
                 CompactAppointmentView(appointment: nextAppointment)
             }
         }
         .frame(maxWidth: .infinity)
         .padding()
         .background(Color(.systemBackground))
         .cornerRadius(16)
         .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
     }
 }
 // MARK: - Compact Progress View
 struct CompactProgressView: View {
     @EnvironmentObject var progressVM: ProgressViewModel
 
     
     var body: some View {
         VStack(alignment: .leading, spacing: 8) {
             HStack(spacing: 4) {
                 Image(systemName: "figure.run")
                     .font(.caption)
                     .foregroundColor(.accent)
                 Text("Training")
                     .font(.caption)
                     .foregroundColor(.secondary)
             }
             
             // Progress Ring (kleiner)
             ZStack {
                 Circle()
                     .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                     .frame(width: 50, height: 50)
                 
                 Circle()
                     .trim(from: 0, to: progressVM.dailyProgress)
                     .stroke(
                         LinearGradient(
                            colors: [.accent, .accent.opacity(0.7)],
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing
                         ),
                         style: StrokeStyle(lineWidth: 6, lineCap: .round)
                     )
                     .frame(width: 50, height: 50)
                     .rotationEffect(.degrees(-90))
                     .animation(.easeInOut, value: progressVM.dailyProgress)
                 
                 Text("\(Int(progressVM.dailyProgress * 100))%")
                     .font(.caption2)
                     .fontWeight(.bold)
             }
             
             Text("\(progressVM.remainingMinutes) Min")
                 .font(.caption)
                 .foregroundColor(.secondary)
         }
         .frame(maxWidth: .infinity, alignment: .leading)
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
             
             Text(appointment.timeString)
                 .font(.title3)
                 .fontWeight(.semibold)
                 .foregroundColor(.primary)
             
             Text(appointment.dateString)
                 .font(.caption)
                 .foregroundColor(.secondary)
             
             Text(appointment.therapist)
                 .font(.caption)
                 .foregroundColor(.secondary)
         }
         .frame(maxWidth: .infinity, alignment: .leading)
     }
 }
 struct ExerciseTypeBadge: View {
     let type: ExerciseCategory
     let count: Int
     let duration: Int
     
     var body: some View {
         HStack(spacing: 6) {
             Image(systemName: type.icon)
                 .font(.caption2)
                 .foregroundColor(type.color)
             
             VStack(alignment: .leading, spacing: 0) {
                 Text(type.rawValue)
                     .font(.caption2)
                     .fontWeight(.medium)
                 
                 Text("\(duration) Min")
                     .font(.caption2)
                     .foregroundColor(.secondary)
             }
             
             Spacer()
         }
         .padding(.horizontal, 10)
         .padding(.vertical, 6)
         .background(type.color.opacity(0.1))
         .cornerRadius(8)
     }
 }
#Preview {
    let deps = AppDependencies.shared  // ✅ Nimm einfach die echte Dependency!
    
    DailyProgressCard()
      //  .environmentObject(deps.trainingData)
        .environmentObject(WeeklySettings())
        .environmentObject(deps.progressViewModel)
        .environmentObject(deps.appointmentViewModel)  // ✅ Aus AppDependencies!
        .modelContainer(deps.modelContainer)
}
