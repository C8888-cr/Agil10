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
