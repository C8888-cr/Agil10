//
//  ExercisesSection.swift
//  Agil10.0
//
//  Created by Christiane Roth on 16.12.25.
//

import SwiftUI
import SwiftData

struct ExercisesSection: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedScheduleId: UUID?  // ← NEU!
    @State private var showVideoPlayer = false  // ← NEU!
    @State private var selectedVideoForPlayer: Video?  // ← NEU!
    @State private var editingScheduleId: UUID?  // ← Für EDIT!
    @State private var isEditingMode = false
    @State private var activeSheet: SheetType?
    @State private var selectedVideoForConfig: Video?
    @State private var playbackSettings = PlaybackSettings()
    
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    enum SheetType: Identifiable {
        case
        library,
        profile,
        settings
        var id: Self { self }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(progressVM.todaysSchedules, id: \.id) { schedule in
                let video = schedule.video ?? Video.previewMobility
                
                VideoScheduleRow(
                    schedule: schedule,
                    video: video,
                    onToggleCompletion: {
                        progressVM.toggleCompletion(schedule, for: appState.currentUser)
                    },
                    onDelete: {
                        progressVM.removeSchedule(schedule, for: appState.currentUser)
                    },
                    
                    onConfig: {
                        editingScheduleId = schedule.id
                        selectedVideoForConfig = video
                        playbackSettings = PlaybackSettings(
                            repetitions: schedule.effectiveRepetitions,
                            pauseSeconds: schedule.effectivePauseSeconds,
                            loopDurationSeconds: schedule.effectiveLoopDurationSeconds
                        )
                    },
                    onPlay: { video in  // ← VIDEO empfangen!
                        selectedVideoForPlayer = video
                        selectedScheduleId = schedule.id  // ← Schedule merken!
                        showVideoPlayer = true
                    }
                )
                Divider()
            }
            
            if progressVM.canAddMoreVideos {
                Button {
                    activeSheet = .library
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

