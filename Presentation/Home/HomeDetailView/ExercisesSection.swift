import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExercisesSection: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var session: SessionManager
    
    
    @State private var draggedScheduleId: UUID? = nil
    @State private var dropTargetId: UUID? = nil
    @State private var dropIndicator: ScheduleDropIndicator? = nil
    
    let onToggleCompletion: (VideoSchedule) -> Void
    let onDelete: (VideoSchedule) -> Void
    let onConfig: (VideoSchedule) -> Void
    let onPlay: (VideoSchedule, Video) -> Void
    let onAddVideo: () -> Void
    let onRate: (VideoSchedule, Int) -> Void
    let onPlayAll: () -> Void
    
        
    
    private var remainingSeconds: Int {
        let targetSeconds = progressVM.targetMinutes * 60
        let totalScheduled = progressVM.todaysSchedules.reduce(0) { $0 + $1.totalDurationSeconds }
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
                            .foregroundStyle(.accent)
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
                        expertModeEnabled: settingsVM.preferences.expertModeEnabled,
                        onToggleCompletion: { onToggleCompletion(schedule) },
                        onDelete: { onDelete(schedule) },
                        onConfig: { onConfig(schedule) },
                        onPlay: { video in onPlay(schedule, video) },
                        onRate: { rating in onRate(schedule, rating) }
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: VideoSchedule.self, Video.self,
        configurations: config
    )
    let context = ModelContext(container)

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

    // ← SessionManager korrekt instanziieren
    let sessionManager = SessionManager(
        userRepository: UserRepository(modelContext: context)
    )
 
    let repository = VideoScheduleRepository(modelContext: context)
    let settingsVM = SettingsViewModel(
        modelContext: context,
        session: sessionManager,
        addScheduleUseCase: AddScheduleUseCase(repository: repository),
        removeScheduleUseCase: RemoveScheduleUseCase(repository: repository)
    )
    let progressVM = ProgressPreviewHelper.makeProgressVM(context: context)
    
    
  return ExercisesSection(
        onToggleCompletion: { _ in },
        onDelete: { _ in },
        onConfig: { _ in },
        onPlay: { _, _ in },
        onAddVideo: { },
        onRate: { _, _ in },
        onPlayAll: { }
    )
    .environmentObject(progressVM)
    .environmentObject(settingsVM)
    .modelContainer(container)
    .environmentObject(sessionManager)
}
