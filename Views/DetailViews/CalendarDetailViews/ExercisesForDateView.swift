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
        VStack(alignment: .leading, spacing: 12) {
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
                              if let video = schedule.video {
                        VideoListRow(
                            video: video,
                            onTap: { video in
                                print("Exercise tapped: \(video.title)")
                            },
                            onFavorite: {
                                
                                Task {
                                    if let user = authService.currentUser {
                                        //await
                                       videoLibraryViewModel.deleteVideo(video, for: user)
                                    }
                                }
                            },
                            onDelete: {
                                                           if let user = authService.currentUser {
                                                               progressVM.removeSchedule(schedule, for: user)
                                                           }
                                                       }
                                                   )
                                               }
                                           }
            } else {
                EmptyExercisesView(onAddExercise: onAddExercise)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
