//
//  DailyTemplateView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 14.03.26.
//


import SwiftUI
import SwiftData

struct DailyTemplateView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel
    @EnvironmentObject var authService: AuthService
    
    @State private var showLibrary = false
    @State private var selectedVideoForConfig: Video?
    
    // Template-Videos aus SettingsVM holen
    private var templateSchedules: [VideoSchedule] {
        settingsVM.dailyTemplates
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Info-Banner
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accent)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tages-Vorlage")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Diese Videos werden täglich an allen aktiven Trainingstagen angezeigt.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Video-Liste
                Section {
                    if templateSchedules.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "video.slash")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Noch keine Videos")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Tippe auf + um Videos hinzuzufügen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                    } else {
                        ForEach(templateSchedules, id: \.id) { schedule in
                            if let video = schedule.video {
                                templateVideoRow(schedule: schedule, video: video)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                settingsVM.removeDailyTemplate(
                                    templateSchedules[index],
                                    user: authService.currentUser!
                                )
                            }
                        }
                    }
                    
                    // + Hinzufügen Button
                    Button {
                        showLibrary = true
                    } label: {
                        Label("Video hinzufügen", systemImage: "plus.circle.fill")
                            .foregroundColor(.accent)
                    }
                    
                } header: {
                    Label("Videos in der Vorlage", systemImage: "list.bullet")
                } footer: {
                    if !templateSchedules.isEmpty {
                        Text("Gesamtdauer: \(totalDurationText)")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Tages-Vorlage")
            .navigationBarTitleDisplayMode(.inline)
            
            // Library Sheet
            .sheet(isPresented: $showLibrary) {
                NavigationStack {
                    LibraryView(
                        onVideoSelected: { video in
                            showLibrary = false
                            // Kurze Verzögerung damit Library-Sheet erst schließt
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                selectedVideoForConfig = video
                            }
                        }
                    )
                    .environmentObject(authService)
                    .environmentObject(videoLibraryVM)
                    .environmentObject(settingsVM)
                }
            }
            
            // Quick Config Sheet
            .sheet(item: $selectedVideoForConfig) { video in
                VideoQuickConfigSheet(
                    video: video,
                    onAdd: { reps, loopDuration, pause in
                        if let user = authService.currentUser {
                            settingsVM.addDailyTemplate(
                                video: video,
                                repetitions: reps,
                                loopDurationSeconds: loopDuration,
                                pauseSeconds: pause,
                                user: user
                            )
                        }
                        selectedVideoForConfig = nil
                    },
                    onCancel: {
                        selectedVideoForConfig = nil
                    }
                )
            }
        }
    }
    
    private func templateVideoRow(schedule: VideoSchedule, video: Video) -> some View {
        HStack(spacing: 12) {
            // Thumbnail oder Placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accent.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "play.fill")
                        .foregroundColor(.accent)
                        .font(.caption)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Label("\(schedule.effectiveRepetitions)×", systemImage: "repeat")
                    Label("\(schedule.effectiveLoopDurationSeconds / 60) Min", systemImage: "timer")
                    Label("\(schedule.effectivePauseSeconds)s", systemImage: "pause.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(schedule.formattedDuration)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.accent)
        }
        .padding(.vertical, 4)
    }
    
    private var totalDurationText: String {
        let total = templateSchedules.reduce(0) { $0 + $1.totalDurationSeconds }
        let m = total / 60
        let s = total % 60
        return s > 0 ? "\(m):\(String(format: "%02d", s)) Min" : "\(m) Min"
    }
}