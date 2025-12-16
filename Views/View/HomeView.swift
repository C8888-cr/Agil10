
import SwiftUI
import SwiftData

struct HomeView: View {
    let user: User

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
                    exercisesSection
                    
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
                    SettingsView(user: user) // ← user Parameter
                        .environmentObject(settingsVM)   // ← VM injizieren!
                        .environment(\.modelContext, settingsVM.modelContext)
                        .onDisappear {  // ← WICHTIG!
                            progressVM.loadToday(for: user)  // ← REFRESH!
                        }
                case .profile:
                    ProfileView()
                case .library:
                    LibraryView(
                        currentUser: user,
                        repository: videoLibraryVM.repository,
                        onVideoSelected: { video in
                                       // Direkt adden OHNE Config!
                                       progressVM.addVideo(video, for: user)
                                       activeSheet = nil
                            

                        }
                    )
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
                            
                            // Deine ursprüngliche Methode
                            progressVM.updateSchedule(schedule, for: user)
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
            progressVM.loadToday(for: user)
        }
    }
    
    // MARK: - Fortschrittsring
    private var compactRingView: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.accent.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progressVM.dailyProgress))
                    .stroke(
                        LinearGradient(colors: [.accent, .accent],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progressVM.dailyProgress)
                
                Text("\(Int(progressVM.dailyProgress * 100))%")
                    .font(.headline)
                    .foregroundColor(.accent)
            }
            Text("Tagesziel")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
 /*
    // MARK: - Übungen Section - VIDEO SCHEDULE ROW
    private var exercisesSection: some View {
        VStack(spacing: 0) {
            ForEach(progressVM.todaysSchedules, id: \.id) { schedule in  // ← VideoSchedule!
                VideoScheduleRow(
                    schedule: schedule,
                    video: schedule.video ?? Video.previewMobility,
                    onToggleCompletion: {
                        progressVM.toggleCompletion(schedule, for: currentUser)
                    },
                    onDelete: {
                        progressVM.removeSchedule(schedule, for: currentUser)
                    },
                    onConfig: {                                        editingScheduleId = schedule.id  // ← WICHTIG!
                                        selectedVideoForConfig = schedule.video ?? Video.previewMobility
                                        playbackSettings = PlaybackSettings(
                                            repetitions: schedule.effectiveRepetitions,  // ← Schedule!
                                            pauseSeconds: schedule.effectivePauseSeconds,  // ← Schedule!
                                            loopDurationSeconds: schedule.effectiveLoopDurationSeconds  // ← Schedule!
                            )
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
*/
    
    private var exercisesSection: some View {
        VStack(spacing: 0) {
            ForEach(progressVM.todaysSchedules, id: \.id) { schedule in
                let video = schedule.video ?? Video.previewMobility
                
                VideoScheduleRow(
                    schedule: schedule,
                    video: video,
                    onToggleCompletion: {
                        progressVM.toggleCompletion(schedule, for: user)
                    },
                    onDelete: {
                        progressVM.removeSchedule(schedule, for: user)
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
#Preview("HomeView") {
    let container = PreviewHelper.createModelContainer()
    let context = ModelContext(container)
    
    let mockUser = MockAuthService.mockPatient
    let progressVM = ProgressViewModel(modelContext: context)
    let videoLibraryVM = VideoLibraryViewModel(repository: VideoRepositoryMock())
    let settingsVM = SettingsViewModel(modelContext: context)
    
    // ✅ AppState OHNE currentUser setzen!
    let appState = AppState(modelContext: context, authService: MockAuthService())
    
    HomeView(user: mockUser)  // ← NUR user-Parameter!
        .modelContainer(container)
        .environmentObject(progressVM)
        .environmentObject(videoLibraryVM)
        .environmentObject(settingsVM)
        .environmentObject(appState)
        .environmentObject(TrainingData(weeklySettings: WeeklySettings()))
}
