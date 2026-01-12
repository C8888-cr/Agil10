import SwiftUI
import SwiftData
struct ExercisesForDateView: View {
    let selectedDate: Date
    
    let onAddExercise: () -> Void
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var videoLibraryViewModel: VideoLibraryViewModel
    @EnvironmentObject var authService: AuthService
    
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.accent)
                Text("Training \(selectedDate, format: .dateTime.day().month())")
                    .font(.headline)
                Spacer()
                Text(remainingMinutes > 0 ? "Noch \(remainingMinutes) Min." : "Fertig!")
                    .font(.subheadline)
                    .foregroundStyle(remainingMinutes > 0 ? .secondary : Color.green)
            }
            
            if !schedulesForDate.isEmpty {
                ForEach(schedulesForDate) { schedule in
                    let video = schedule.video ?? Video.previewMobility
                    
                    VideoScheduleRow(
                        schedule: schedule,
                        video: video,
                        onToggleCompletion: {  },  // ← AUS!
                        onDelete: {
                            if let user = authService.currentUser {
                                progressVM.removeSchedule(schedule, for: user)
                            }
                        },
                        onConfig: {
                            print("Config tapped")
                        },
                        onPlay: { video in
                            print("Play: \(video.title)")
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                 //       .padding(.horizontal, 16)
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
        }
        .padding()
 
    }
    // ✅ HELPER: Schedules für selectedDate filtern
    private var schedulesForDate: [VideoSchedule] {
        let calendar = Calendar.current
        return progressVM.todaysSchedules.filter { schedule in
            calendar.isDate(schedule.scheduledDate, inSameDayAs: selectedDate)
        }
    }
    // ← HIER EINFÜGEN (neue Computed Properties):
        private var trainingMinutesForDate: Int {
            progressVM.getTodaysTargetMinutes(from: settingsVM, for: selectedDate)
        }
        
        private var remainingMinutes: Int {
            let target = trainingMinutesForDate
            let totalScheduled = schedulesForDate.reduce(0) { $0 + ($1.totalDurationSeconds / 60) }
            return max(0, target - totalScheduled)
        }

  
}
