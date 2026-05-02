import SwiftUI
import SwiftData
import UniformTypeIdentifiers


struct ExercisesForDateView: View {
    
    let selectedDate: Date
    let onAddExercise: () -> Void
    let onConfig: (VideoSchedule) -> Void
    let onPlay: (VideoSchedule, Video) -> Void
    var onDelete: ((VideoSchedule) -> Void)? = nil

    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var videoLibraryViewModel: VideoLibraryViewModel
    @EnvironmentObject var session: SessionManager
    
    @State private var draggedScheduleId: UUID? = nil
    @State private var dropIndicator: ScheduleDropIndicator? = nil

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                if remainingSeconds == 0 && !schedulesForDate.isEmpty {
                    Text("Fertig!")
                        .font(.subheadline)
                        .foregroundStyle(Color.green)
                }
            }
            
            if !schedulesForDate.isEmpty {
                ForEach(schedulesForDate) { schedule in
                    let video = schedule.video ?? Video.previewMobility
                    
                    VStack(spacing: 0) {
                        // Linie OBEN
                        dropLine(visible: dropIndicator == ScheduleDropIndicator(targetId: schedule.id, position: .above))
                        
                        VideoScheduleRow(
                            schedule: schedule,
                            video: video,
                            expertModeEnabled: settingsVM.preferences.expertModeEnabled,
                            onDelete: {
                                if let onDelete = onDelete {
                                    onDelete(schedule)
                                } else if let user = session.currentUser {
                                    progressVM.removeSchedule(schedule, for: user)
                                }
                            },
                            onConfig: {
                                onConfig(schedule)
                                print("Config tapped")
                            },
                            onPlay: { video in
                                onPlay(schedule, video)
                            }
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                                          let sourceSchedule = schedulesForDate.first(where: { $0.id == draggedId })
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
                        
                        // Linie UNTEN
                        dropLine(visible: dropIndicator == ScheduleDropIndicator(targetId: schedule.id, position: .below))
                    }
                    .animation(.easeInOut(duration: 0.15), value: dropIndicator)
                }
            } else {
                EmptyExercisesView(onAddExercise: onAddExercise)
            }

            if progressVM.canAddMoreVideos {
                Button {
                    onAddExercise()
                } label: {
                    Label("Video hinzufügen", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            if remainingSeconds > 0 {
                RemainingTimeCard(remainingSeconds: remainingSeconds)
            }
        }
        .padding()
    }
    
    // MARK: - Drop Line Helper
    
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
    
    // MARK: - Helpers
    
    private var schedulesForDate: [VideoSchedule] {
        let calendar = Calendar.current
        return progressVM.todaysSchedules.filter { schedule in
            calendar.isDate(schedule.scheduledDate, inSameDayAs: selectedDate)
        }
    }
    
    private var trainingMinutesForDate: Int {
        progressVM.targetMinutes
    }
    
    private var remainingSeconds: Int {
        let targetSeconds = trainingMinutesForDate * 60
        let totalScheduled = schedulesForDate.reduce(0) { $0 + $1.totalDurationSeconds }
        return max(0, targetSeconds - totalScheduled)
    }

    private var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        if minutes == 0 { return "\(seconds) Sek" }
        if seconds == 0 { return "\(minutes) Min" }
        return "\(minutes):\(String(format: "%02d", seconds)) Min"
    }
}
