import SwiftUI
import SwiftData
struct ExercisesForDateView: View {
    let selectedDate: Date
    let onAddExercise: () -> Void
    
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var videoLibraryViewModel: VideoLibraryViewModel
    @EnvironmentObject var authService: AuthService
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.accent)
                Text("Übungen für heute")
                    .font(.headline)
                Spacer()
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
}
