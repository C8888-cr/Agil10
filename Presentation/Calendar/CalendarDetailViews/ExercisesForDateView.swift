import SwiftUI
import SwiftData
struct ExercisesForDateView: View {
    
    
    let selectedDate: Date
    let onAddExercise: () -> Void
    let onConfig: (VideoSchedule) -> Void    // ← NEU!
    let onPlay: (VideoSchedule, Video) -> Void // ← NEU!
    var onDelete: ((VideoSchedule) -> Void)? = nil

    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var videoLibraryViewModel: VideoLibraryViewModel
    @EnvironmentObject var session: SessionManager
    
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.accent)
                Text("Training \(selectedDate, format: .dateTime.day().month())")
                    .font(.headline)
                Spacer()
                // ✅ "Fertig!" bleibt, aber kein "Noch X Min" mehr hier
                if remainingSeconds == 0 && !schedulesForDate.isEmpty {
                    Text("Fertig!")
                        .font(.subheadline)
                        .foregroundStyle(Color.green)
                }
            }
            
            if !schedulesForDate.isEmpty {
                ForEach(schedulesForDate) { schedule in
                    let video = schedule.video ?? Video.previewMobility
                    
                    VideoScheduleRow(
                        schedule: schedule,
                        video: video,
                        onToggleCompletion: {  },  // ← AUS!
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
                        },
                        onRate: { rating in
                                if let user = session.currentUser {
                                    schedule.rating = rating
                                    progressVM.updateSchedule(schedule, for: user)
                                }
                            }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
             //       Divider()
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
                // ✅ Wie in HomeView — direkt unter Button
                        if remainingSeconds > 0 {
                            RemainingTimeCard(remainingSeconds: remainingSeconds)
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
