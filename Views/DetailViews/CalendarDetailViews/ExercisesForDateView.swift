import SwiftUI
import SwiftData
struct ExercisesForDateView: View {
    let selectedDate: Date
    let onAddExercise: () -> Void
    
    @EnvironmentObject var trainingViewModel: TrainingViewModel
    @EnvironmentObject var videoLibraryViewModel: VideoLibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.accent)
                Text("Übungen für heute")
                    .font(.headline)
                Spacer()
            }
            
            if let exercises = trainingViewModel.exercises(for: selectedDate),
               !exercises.isEmpty {
                ForEach(exercises) { exercise in
                    // ✅ Video direkt aus allVideos suchen
                    if let video = videoLibraryViewModel.allVideos.first(where: { $0.id == exercise.videoId }) {
                        VideoListRow(
                            video: video,
                            onTap: { video in
                                print("Exercise tapped: \(video.title)")
                            },
                            onFavorite: {
                                videoLibraryViewModel.toggleFavorite(video)
                            },
                            onDelete: {
                                trainingViewModel.removeExercise(exercise.id, from: selectedDate)
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
}
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Video.self, configurations: config)
    
    ExercisesForDateView(
        selectedDate: Date(),
        onAddExercise: { print("Add exercise") }
    )
    .environmentObject(TrainingViewModel())
    .environmentObject(VideoLibraryViewModel(
        repository: VideoRepository(modelContext: ModelContext(container))
    ))
    .padding()
}
