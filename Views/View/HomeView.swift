
import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var trainingData: TrainingData 

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
     
            ScrollView {
                VStack(spacing: 20) {
                    // Fortschrittsring
                   // compactRingView
                    DailyProgressCard()
                    // Liste der heutigen Videos
                    ExercisesSection(
                        onToggleCompletion: { schedule in
                        progressVM.toggleCompletion(schedule, for: authService.currentUser!)
                                   },
                        onDelete: { schedule in
                                       progressVM.removeSchedule(schedule, for: authService.currentUser!)
                                   },
                        onConfig: { schedule in
                                       editingScheduleId = schedule.id
                                       selectedVideoForConfig = schedule.video ?? Video.previewMobility
                                       playbackSettings = PlaybackSettings(/* ... */)
                                   },
                        onPlay: { schedule, video in
                                       selectedScheduleId = schedule.id
                                       selectedVideoForPlayer = video
                                       showVideoPlayer = true
                                   },
                        onAddVideo: {
                                       activeSheet = .library  // ← Sheet öffnet sich!
                                   }
                               )
                           
                       
                    // Restzeit
                    if progressVM.remainingMinutes > 0 {
                        remainingTimeCard
                    }
                }
                .padding()
            }
            .navigationTitle("Heute")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Profil") { activeSheet = .profile }
                            Button("Einstellungen") { activeSheet = .settings }
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                }
            }

            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .settings:
                    SettingsView() // ← user Parameter
                        .environmentObject(settingsVM)   // ← VM injizieren!
                        .environment(\.modelContext, settingsVM.modelContext)
                        .onDisappear {
                            progressVM.loadToday(for: authService.currentUser!)
                        }
                        
                case .profile:
                    ProfileView()
                case .library:
                    LibraryView()
                    /*
                        repository: AppDependencies.shared.videoRepository,
                     
                        onVideoSelected: { video in
                            progressVM.addVideo(video, for: authService.currentUser!)  // ✅ Direkt!
                            activeSheet = nil
                        }
                    )
                    .environmentObject(authService)
                     */
           /*     case .config:
                    if let video = selectedVideoForConfig {
                        NavigationStack {
                            VideoScheduleConfigSheet(
                                video: video,
                                repetitions: $playbackSettings.repetitions,
                                pauseSeconds: $playbackSettings.pauseSeconds,
                                loopDuration: $playbackSettings.loopDurationSeconds, // ✅ Property ergänzt
                                onAdd: {
                                    print("➕ VIDEO HINZUFÜGEN: \(video.title)")
                                    progressVM.addVideo(
                                        video,
                                        for: currentUser,
                                        customRepetitions: playbackSettings.repetitions,  // ✅ Int
                                        customPauseSeconds: playbackSettings.pauseSeconds // ✅ Int
                                    )
                                    activeSheet = nil
                                    selectedVideoForConfig = nil
                                },
                                onCancel: {
                                    activeSheet = nil
                                    selectedVideoForConfig = nil
                                }
                        )
                        }
                    }*/
                }
        }
        
            .sheet(item: $selectedVideoForConfig) { video in
                VideoScheduleConfigSheet(
                    video: video,
                    repetitions: $playbackSettings.repetitions,
                    pauseSeconds: $playbackSettings.pauseSeconds,
                    loopDuration: $playbackSettings.loopDurationSeconds,
                    onAdd: {
                        print("🔍 Speichern...")
                        
                        if let scheduleId = editingScheduleId,
                           let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }) {
                            
                            // ✅ WICHTIG: Werte SETZEN vor updateSchedule!
                            schedule.customRepetitions = playbackSettings.repetitions
                            schedule.customPauseSeconds = playbackSettings.pauseSeconds
                            schedule.customLoopDurationSeconds = playbackSettings.loopDurationSeconds
                            
                            print("📝 Werte gesetzt: \(playbackSettings.repetitions)×")
                            progressVM.updateSchedule(schedule, for: authService.currentUser!)

                        }
           
                        selectedVideoForConfig = nil
                        editingScheduleId = nil
                    },
                    onCancel: {
                        selectedVideoForConfig = nil
                        editingScheduleId = nil
    

                    }
                )
            }
            .sheet(isPresented: $showVideoPlayer) {
                if let video = selectedVideoForPlayer,
                   let scheduleId = selectedScheduleId {
                    VideoPlayerView(
                        video: video,
                        scheduleId: scheduleId,  // ✅ DEINE STATE VARIABLE!
                        progressViewModel: progressVM
                    )
                }
            }

            .onAppear {
                print("🏠 HomeView onAppear - currentUser.email: '\(authService.currentUser!.email)'")
                progressVM.loadToday(for: authService.currentUser!)
            }

            
    }
    


    // ✅ NEUE VIEW: Gesamtdauer + Play
    private func totalDurationRow(for schedule: any PersistentModel, video: Video) -> some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundStyle(.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Gesamt: \(calculateTotalDuration(schedule: schedule, video: video))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Konfigurieren")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("⏯️ Abspielen") {
                print("▶️ Player starten: \(video.title)")
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accent.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // ✅ SICHERE Dauer-Berechnung
    private func calculateTotalDuration(schedule: any PersistentModel, video: Video) -> String {
        // Annahme: schedule hat repetitions, pauseSeconds, loopDurationSeconds als Int
        let loopDuration = 120  // Fallback
        let repetitions = 3     // Fallback
        let pauseSeconds = 30   // Fallback
        
        let totalSeconds = (loopDuration * repetitions) + max(0, (repetitions - 1) * pauseSeconds)
        
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return secs > 0 ? "\(minutes):\(String(format: "%02d", secs)) Min" : "\(minutes) Min"
    }


    // MARK: - Restzeit
    private var remainingTimeCard: some View {
        HStack {
            Image(systemName: "clock")
            Text("Noch \(progressVM.remainingMinutes) Minuten übrig")
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
