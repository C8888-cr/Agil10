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
    
    // NUR CALLBACKS nach oben!
    let onToggleCompletion: (VideoSchedule) -> Void
    let onDelete: (VideoSchedule) -> Void
    let onConfig: (VideoSchedule) -> Void
    let onPlay: (VideoSchedule, Video) -> Void
    let onAddVideo: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
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
                Divider()
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
                .padding()
            }
        }
    }
}
#Preview {
    // In‑Memory Container nur für die Preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: VideoSchedule.self, Video.self,
        configurations: config
    )
    
    // Kontext über den Container holen
    let context = ModelContext(container)
    
    // Beispiel‑Daten
    let schedule1 = VideoSchedule(
        scheduledDate: Date(),
        orderIndex: 0,
        video: .previewMobility
    )
    let schedule2 = VideoSchedule(
        scheduledDate: Date(),
        orderIndex: 1,
        video: .previewStrength
    )
    
    context.insert(schedule1)
    context.insert(schedule2)
    
    // ViewModel mit Kontext initialisieren
    let progressVM = ProgressViewModel(modelContext: context)
    progressVM.todaysSchedules = [schedule1, schedule2]
    
    return ExercisesSection(
        onToggleCompletion: { _ in },
        onDelete: { _ in },
        onConfig: { _ in },
        onPlay: { _, _ in },
        onAddVideo: { }
    )
    .environmentObject(progressVM)
    .modelContainer(container)
}
