
import SwiftUI
import SwiftData
import AVKit

struct VideoScheduleRow: View {
    let schedule: VideoSchedule
    let video: Video
    
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void
    let onConfig: () -> Void
    let onPlay: (Video) -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 8) {
                // 1. Thumbnail with Play overlay
                ZStack {
                    thumbnailView
                        .frame(width: 100, height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button(action: { onPlay(video) }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                    }
                }
                
                // 2. Info section
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(schedule.isCompleted ? .secondary : .primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Label("\(schedule.effectiveRepetitions)×", systemImage: "repeat")
                            .font(.caption2)
                    }
                    
                    HStack(spacing: 8) {
                        Label(schedule.formattedDuration, systemImage: "clock")
                            .font(.caption2)
                        if schedule.effectivePauseSeconds > 0 {
                            Label("\(schedule.effectivePauseSeconds)s", systemImage: "pause")
                                .font(.caption2)
                        }
                    }
                }
                
                Spacer()
                
                // 3. Actions
                VStack(spacing: 0) {
                    Menu {
                        Button("Konfigurieren") { onConfig() }
                        Button("Löschen", role: .destructive) { showDeleteAlert = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: onToggleCompletion) {
                        Image(systemName: schedule.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(schedule.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            .frame(height: 75)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(schedule.isCompleted ? Color.green.opacity(0.1) : Color(.systemBackground))
            .opacity(schedule.isCompleted ? 0.7 : 1.0)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            .overlay(alignment: .bottomTrailing) {
                if let rating = schedule.rating {
                    RatingEmojiView(rating: rating)
                        .font(.caption2)
                        .padding(.trailing, 16)
                        .padding(.bottom, 8)
                }
            }
            
            .alert("Löschen?", isPresented: $showDeleteAlert) {
                Button("Löschen", role: .destructive) { onDelete() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("'\(video.title)' entfernen?")
            }
        }
    }
    private var thumbnailView: some View {
        Group {
            if let thumbnailFileName = video.thumbnailFileName,
               let thumbnail = ThumbnailGeneratorService.shared.loadThumbnail(fileName: thumbnailFileName) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.secondary.opacity(0.2)
                    Image(systemName: "video.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("VideoScheduleRow") {
    VStack(spacing: 20) {
        VideoScheduleRow(
            schedule: createMockSchedule(completed: false, rating: nil),
            video: createMockVideo(),
            onToggleCompletion: { print("✅ Toggle") },
            onDelete: { print("🗑️ Delete") },
            onConfig: { print("⚙️ Config") },
            onPlay: { video in print("▶️ Play: \(video.title)") }
        )
        
    //    Divider()
        
        VideoScheduleRow(
            schedule: createMockSchedule(completed: true, rating: 5),
            video: createMockVideo(title: "Rücken Dehnung"),
            onToggleCompletion: { print("✅ Toggle") },
            onDelete: { print("🗑️ Delete") },
            onConfig: { print("⚙️ Config") },
            onPlay: { video in print("▶️ Play: \(video.title)") }
        )
    }
    .padding()
}

// MARK: - Preview Helpers
private func createMockVideo(title: String = "Schulter Mobilisation") -> Video {
    Video(
        title: title,
        videoFileName: "shoulder.mov",
        category: .mobility,
        bodyRegion: .cervicalSpine,
        equipment: .noEquipment,
        durationSeconds: 120,
        defaultRepetitions: 3,
        defaultPauseSeconds: 30,
        loopDurationSeconds: 120,
        rating: 1
    )
}

private func createMockSchedule(completed: Bool, rating: Int?) -> VideoSchedule {
    let schedule = VideoSchedule(
        scheduledDate: Date(),
        orderIndex: 0,
        video: createMockVideo(),
        customRepetitions: 4,
        customPauseSeconds: 45,
        customLoopDurationSeconds: 180
    )
    schedule.isCompleted = completed
    schedule.rating = rating
    if completed {
        schedule.completedAt = Date()
    }
    return schedule
}
