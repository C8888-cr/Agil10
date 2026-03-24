//
//  ExercisesSection.swift
//  Agil10.0
//
//  Created by Christiane Roth on 16.12.25.
//

import SwiftUI
import SwiftData

struct ExercisesSection: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    // NUR CALLBACKS nach oben!
    let onToggleCompletion: (VideoSchedule) -> Void
    let onDelete: (VideoSchedule) -> Void
    let onConfig: (VideoSchedule) -> Void
    let onPlay: (VideoSchedule, Video) -> Void
    let onAddVideo: () -> Void
    
    private var remainingSeconds: Int {
           let targetSeconds = progressVM.getTodaysTargetMinutes(from: settingsVM, for: Date()) * 60
           let totalScheduled = progressVM.todaysSchedules.reduce(0) { $0 + $1.totalDurationSeconds }
           return max(0, targetSeconds - totalScheduled)
       }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(progressVM.todaysSchedules, id: \.id) { schedule in
                let video = schedule.video ?? Video.previewMobility
                
                VideoScheduleRow(
                    schedule: schedule,
                    video: video,
                    onToggleCompletion: {
                        onToggleCompletion(schedule)  // ← CALLBACK statt direkt!
                    },
                    onDelete: {
                        onDelete(schedule)  // ← CALLBACK!
                    },
                    onConfig: {
                        onConfig(schedule)  // ← CALLBACK!
                    },
                    onPlay: { video in
                        onPlay(schedule, video)  // ← CALLBACK!
                    }
                )
            //    Divider()
            }
            
            if progressVM.canAddMoreVideos {
                Button {
                    onAddVideo()  // ← CALLBACK!
                } label: {
                    Label("Video hinzufügen", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            if remainingSeconds > 0 {
                           RemainingTimeCard(remainingSeconds: remainingSeconds)
                       }
        }
 
    }
}

/*
#Preview {
    // In‑Memory Container nur für die Preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: VideoSchedule.self, Video.self,
        configurations: config
    )
    
    // Kontext über den Container holen
    let context = ModelContext(container)

    
    let authService = AuthService(authServiceProtocol: MockAuthService(modelContext: context))
    
    let settingsVM = SettingsViewModel(modelContext: container.mainContext, authService: AppDependencies.shared.authService)
    
    // ViewModel mit Kontext initialisieren
    let repository = VideoScheduleRepository(modelContext: context)
    let progressVM = ProgressViewModel(modelContext: modelContext, authService: authService, repository: repository)
  
    
     ExercisesSection(
        onToggleCompletion: { _ in },
        onDelete: { _ in },
        onConfig: { _ in },
        onPlay: { _, _ in },
        onAddVideo: { }
    )
    .environmentObject(progressVM)
    .environmentObject(settingsVM)
    .modelContainer(container)
}
*/
