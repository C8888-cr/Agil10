import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AgilCore

struct ExercisesSection: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var themeManager: ThemeManager
    
    
    @State private var draggedScheduleId: UUID? = nil
    @State private var dropTargetId: UUID? = nil
    @State private var dropIndicator: ScheduleDropIndicator? = nil
    
    let onToggleCompletion: (VideoSchedule) -> Void
    let onDelete: (VideoSchedule) -> Void
    let onConfig: (VideoSchedule) -> Void
    let onPlay: (VideoSchedule, Video) -> Void
    let onAddVideo: () -> Void
    let onRate: (VideoSchedule, Int) -> Void
    let onMobilityFeedback: (VideoSchedule, Double) -> Void
    let onPlayAll: () -> Void
    
    private var remainingSeconds: Int {
            let modus = settingsVM.preferences.workoutModus
            let targetSeconds = progressVM.targetMinutes * 60
            let totalScheduled = progressVM.todaysSchedules.reduce(0) { sum, schedule in
                sum + schedule.effectiveDurationSeconds(modus: modus)
            }
            return max(0, targetSeconds - totalScheduled)
        }
    
    var body: some View {
        VStack(spacing: 12) {
            
            HStack {
                Spacer()
                if progressVM.todaysSchedules.count > 1 {
                    Button {
                        onPlayAll()
                    } label: {
                        Label("Alle abspielen", systemImage: "play.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(themeManager.currentTheme.accentColor)
                    }
                }
            }
            
            ForEach(progressVM.todaysSchedules, id: \.id) { schedule in
                let video = schedule.video ?? Video.previewMobility
                
                VStack(spacing: 0) {
                    // Linie OBEN (vor der Row)
                    dropLine(visible: dropIndicator == ScheduleDropIndicator(targetId: schedule.id, position: .above))
                    
               
                    VideoScheduleRow(
                            schedule: schedule,
                            video: video,
                        workoutModus: settingsVM.preferences.workoutModus,
                        onToggleCompletion: { onToggleCompletion(schedule) },
                        onDelete: { onDelete(schedule) },
                        onConfig: { onConfig(schedule) },
                        onPlay: { video in onPlay(schedule, video) },
                        onRate: { rating in onRate(schedule, rating) },
                        onMobilityFeedback: { value in onMobilityFeedback(schedule, value) }
                    )
                    .opacity(draggedScheduleId == schedule.id ? 0.4 : 1.0)
                    .onDrag {
                        draggedScheduleId = schedule.id
                        return NSItemProvider(object: schedule.id.uuidString as NSString)
                    }
                    .onDrop(
                        of: [.text],
                        delegate: ScheduleDropDelegate(
                            target: schedule,
                            draggedScheduleId: $draggedScheduleId,
                            dropIndicator: $dropIndicator,
                            onMove: { draggedId, targetSchedule, position in
                                guard let user = session.currentUser,
                                      let sourceSchedule = progressVM.todaysSchedules.first(where: { $0.id == draggedId })
                                else { return }
                                
                                switch position {
                                case .above:
                                    progressVM.moveSchedule(sourceSchedule, before: targetSchedule, for: user)
                                case .below:
                                    progressVM.moveSchedule(sourceSchedule, after: targetSchedule, for: user)
                                }
                            }
                        )
                    )
                    
                    // Linie UNTEN (nach der Row)
                    dropLine(visible: dropIndicator == ScheduleDropIndicator(targetId: schedule.id, position: .below))
                }
                .animation(.easeInOut(duration: 0.15), value: dropIndicator)
            }
            
            if progressVM.canAddMoreVideos {
                Button {
                    onAddVideo()
                } label: {
                    Label("Übung hinzufügen", systemImage: "plus.circle.fill")
                }
                .padding(.top, 8)
                .buttonStyle(.primary)
            }
            if remainingSeconds > 0 {
                RemainingTimeCard(remainingSeconds: remainingSeconds)
            }
        }
    }
}

@ViewBuilder
private func dropLine(visible: Bool) -> some View {
    if visible {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor)
            .frame(height: 3)
            .padding(.vertical, 3)
            .transition(.opacity.combined(with: .scale(scale: 0.5)))
    } else {
        Color.clear
            .frame(height: 0)
    }
}
/*
#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    let container: ModelContainer
    let sessionManager: SessionManager
    let settingsVM: SettingsViewModel
    let progressVM: ProgressViewModel
    
    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        self.container = try! ModelContainer(
            for: VideoSchedule.self, Video.self,
            configurations: config
        )
        let context = container.mainContext
        
        let userRepository = UserRepository(modelContext: context)
        let authenticator = LocalAuthBiometricAuthenticator()
        let preferences = UserDefaultsBiometricPreferences()
        let unlockUseCase = UnlockAppUseCase(
            authenticator: authenticator,
            preferences: preferences
        )
        let sessionManager = SessionManager(
                    authService: LocalAuthService(),
                    userRepository: userRepository,
            unlockUseCase: unlockUseCase,
            preferences: preferences
        )
        
        let video1 = Video.previewMobility
        let video2 = Video.previewStrength
        let video3 = Video.previewStretching
        context.insert(video1)
        context.insert(video2)
        context.insert(video3)
        
        let schedule1 = VideoSchedule(scheduledDate: Date(), orderIndex: 0, video: video1)
        let schedule2 = VideoSchedule(scheduledDate: Date(), orderIndex: 1, video: video2)
        let schedule3 = VideoSchedule(scheduledDate: Date(), orderIndex: 2, video: video3)
        context.insert(schedule1)
        context.insert(schedule2)
        context.insert(schedule3)
        try? context.save()
        
        let repository = VideoScheduleRepository(modelContext: context)
        self.settingsVM = SettingsViewModel(
            modelContext: context,
            session: sessionManager,
            addScheduleUseCase: AddScheduleUseCase(repository: repository),
            removeScheduleUseCase: RemoveScheduleUseCase(repository: repository)
        )
        self.progressVM = ProgressPreviewHelper.makeProgressVM(context: context)
    }
    
    var body: some View {
        ExercisesSection(
            onToggleCompletion: { _ in },
            onDelete: { _ in },
            onConfig: { _ in },
            onPlay: { _, _ in },
            onAddVideo: { },
            onRate: { _, _ in },
            onMobilityFeedback: { _, _ in },
            onPlayAll: { }
        )
        .environmentObject(progressVM)
        .environmentObject(settingsVM)
        .modelContainer(container)
        .environmentObject(sessionManager)
    }
}
*/
