//
//  VideoListRowWithSchedule.swift
//  Agil
//
//  Created by Christiane Roth on 09.12.25.
//
/*
import SwiftUI
import SwiftData
import AVKit

struct VideoScheduleRow: View {
    let schedule: VideoSchedule  // ← EXAKT dein Typ!
    let video: Video
    
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void
    let onConfig: () -> Void
 //   let onUpdate: (VideoSchedule) -> Void
    let onPlay: () -> Void
    
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            
            
            // 2. Thumbnail
            thumbnailView
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 3. Info - ECHTE Werte aus schedule!
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(schedule.isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                
                // ✅ ECHTE schedule-Werte!
                HStack(spacing: 6) {
                    Label("\(schedule.effectiveRepetitions)×", systemImage: "repeat")
                        .font(.caption2)
                    
                    Label(schedule.formattedDuration, systemImage: "clock")
                        .font(.caption2)
                    
                    if schedule.effectivePauseSeconds > 0 {
                        Label("\(schedule.effectivePauseSeconds)s", systemImage: "pause")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
                
                // Tags
                HStack(spacing: 8) {
                    Label(video.category.rawValue, systemImage: video.category.icon)
                        .font(.caption2)
                    Label(video.bodyRegion.rawValue, systemImage: video.bodyRegion.icon)
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
            
            Spacer()
            VStack {
                
       
                Button(action: onToggleCompletion) {
                    Image(systemName: schedule.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(schedule.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
                // 4. Actions
                Menu {
                    Button("Konfigurieren") { onConfig() }
                    Button("Löschen", role: .destructive) { showDeleteAlert = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(schedule.isCompleted ? Color.green.opacity(0.1) : Color(.systemBackground))
        .opacity(schedule.isCompleted ? 0.7 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Löschen?", isPresented: $showDeleteAlert) {
            Button("Löschen", role: .destructive) { onDelete() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("'\(video.title)' entfernen?")
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
                Image(systemName: "video.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
#Preview("VideoScheduleRow") {
    let mockVideo = Video(
        title: "Schulter Mobilisation",
        videoFileName: "shoulder.mov",
        category: .mobility,
        bodyRegion: .cervicalSpine,
        equipment: .noEquipment,
        durationSeconds: 120,
        defaultRepetitions: 3,
        defaultPauseSeconds: 30,
        loopDurationSeconds: 120,
        userEmail: "preview@example.com",
        rating: 4
    )
    
    let mockSchedule = VideoSchedule(
        scheduledDate: Date(),
        orderIndex: 0,
        video: mockVideo,
        customRepetitions: 4,      // Custom überschreibt default
        customPauseSeconds: 45,
        customLoopDurationSeconds: 180
    )
    
    VideoScheduleRow(
        schedule: mockSchedule,
        video: mockVideo,
        onToggleCompletion: { print("✅ Toggle completion") },
        onDelete: { print("🗑️ Delete") },
        onConfig: { print("⚙️ Open ConfigSheet") },
    //    onUpdate: { _ in print("updated")}
    )
    .padding()
 
}

#Preview("Completed Schedule") {
    let mockVideo = Video.previewMobility  // Dein Preview Video
    let mockSchedule = VideoSchedule(
        scheduledDate: Date(),
        orderIndex: 1,
        video: mockVideo
    )
   
    
    VideoScheduleRow(
        schedule: mockSchedule,
        video: mockVideo,
        onToggleCompletion: {},
        onDelete: {},
        onConfig: {},
     //   onUpdate: {_ in }
    )
    .padding()
   
}


/*


import SwiftUI
import AVKit
struct VideoScheduleRow: View {
    let schedule: VideoSchedule
    let video: VideoMetadata
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void
    let onUpdate: (VideoSchedule) -> Void
    
    let todayViewModel: TodayViewModel?  // ✅ NEU
    
    @State private var watched = 0.0
    @State private var isEditing = false
    @State private var tempRepetitions: Int = 0
    @State private var tempPauseSeconds: Int = 0
    @State private var showPlayer = false
    
    @State private var viewModel: VideoPlayerViewModel?
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                thumbnailWithProgress
                    .frame(width: 100, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                contentInfo
                
                Spacer()
                
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(schedule.isCompleted ? Color.green.opacity(0.1) : Color(.systemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                // ✅ NEU: ViewModel erstellen beim Öffnen
                               viewModel = VideoPlayerViewModel(videoMetadata: video)
                          showPlayer = true
                      }
        }
        .sheet(isPresented: $showPlayer) {
            VideoPlayerView(videoMetadata: video,
                            todayViewModel: todayViewModel)
               }
        .onAppear {
            tempRepetitions = schedule.effectiveRepetitions
            tempPauseSeconds = schedule.effectivePauseSeconds
        }
    }
    
    // MARK: - Destination
    
    @ViewBuilder
    private var destination: some View {
        VideoPlayerView(videoMetadata: video)
    }
    
    // MARK: - Content Info
    
    private var contentInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(video.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            trainingConfig
            
            categoryInfo
        }
    }
    
    private var trainingConfig: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Label("\(schedule.effectiveRepetitions)×", systemImage: "repeat")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                
                Label("\(schedule.effectivePauseSeconds)s", systemImage: "pause")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                
                Label(formatSeconds(schedule.effectiveLoopDurationSeconds), systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private var categoryInfo: some View {
        HStack(spacing: 12) {
            Label(video.category.rawValue, systemImage: video.category.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Label(video.bodyRegion.rawValue, systemImage: video.bodyRegion.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 8) {
            // Completion Toggle
            Button(action: onToggleCompletion) {
                Image(systemName: schedule.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(schedule.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            
            // Delete
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }
    
    // ✅ NEU: Progress vom ViewModel lesen (mit nil-coalescing)
       private var currentProgress: Double {
           guard let todayViewModel = todayViewModel else { return 0.0 }
           return todayViewModel.getVideoProgress(for: video.id.uuidString)
       }
       
    
    // MARK: - Thumbnail with Progress
    
    private var thumbnailWithProgress: some View {
        ZStack(alignment: .bottomTrailing) {
            thumbnailImage
            
            if !schedule.isCompleted {
                progressRing
            } else {
                completedBadge
            }
        }
    }
    
    private var thumbnailImage: some View {
        Group {
            if let thumbnailFileName = video.thumbnailFileName,
               let thumbnail = ThumbnailGeneratorService.shared.loadThumbnail(fileName: thumbnailFileName) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(uiImage: ThumbnailGeneratorService.shared.getThumbnailOrPlaceholder(fileName: nil))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
    }
    
    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: viewModel?.watchProgress ?? watched)  // ✅ Von ViewModel
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            if let progress = viewModel?.watchProgress, progress > 0 {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 40, height: 40)
        .padding(4)
        .background(Color.black.opacity(0.3))
        .clipShape(Circle())
    }
    
    private var completedBadge: some View {
        ZStack {
            Circle()
                .fill(Color.green)
            
            Image(systemName: "checkmark")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .frame(width: 40, height: 40)
        .padding(4)
    }
    
    // MARK: - Helper
    
    private func formatSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if secs > 0 {
            return "\(minutes):\(String(format: "%02d", secs))"
        }
        return "\(minutes)m"
    }
}
#Preview {
    VideoScheduleRow(
        schedule: VideoSchedule(
            scheduledDate: Date(),
            orderIndex: 0,
            video: VideoMetadata.previewMobility,
            customRepetitions: 3,
            customPauseSeconds: 30
        ),
        video: VideoMetadata.previewMobility,
        onToggleCompletion: { print("Toggled") },
        onDelete: { print("Deleted") },
        onUpdate: { _ in print("Updated") },
        todayViewModel: nil  // ✅ Am Ende + nil ist jetzt erlaubt
    )
}
*/
*/
//
//  VideoListRowWithSchedule.swift
//  Agil
//
//  Created by Christiane Roth on 09.12.25.
//
import SwiftUI
import SwiftData
import AVKit
/*
struct VideoScheduleRow: View {
    let schedule: VideoSchedule
    let video: Video
    
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void
    let onConfig: () -> Void
    let onPlay: (Video) -> Void  // ← NEU! Video übergeben
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            thumbnailView
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(schedule.isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Label("\(schedule.effectiveRepetitions)×", systemImage: "repeat")
                        .font(.caption2)
                    Label(schedule.formattedDuration, systemImage: "clock")
                        .font(.caption2)
                    if schedule.effectivePauseSeconds > 0 {
                        Label("\(schedule.effectivePauseSeconds)s", systemImage: "pause")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Label(video.category.rawValue, systemImage: video.category.icon)
                        .font(.caption2)
                    Label(video.bodyRegion.rawValue, systemImage: video.bodyRegion.icon)
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // ← NEU! Actions: Haken + Play + Menu
            HStack(spacing: 12) {
                // Haken
                Button(action: onToggleCompletion) {
                    Image(systemName: schedule.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(schedule.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
                
                // ← NEU! PLAY BUTTON
                Button(action: { onPlay(video) }) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.accent)
                        .symbolEffect(.pulse, options: .repeating)
                }
                .buttonStyle(.plain)
                
                // Menu
                Menu {
                    Button("Konfigurieren") { onConfig() }
                    Button("Löschen", role: .destructive) { showDeleteAlert = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(schedule.isCompleted ? Color.green.opacity(0.1) : Color(.systemBackground))
        .opacity(schedule.isCompleted ? 0.7 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Löschen?", isPresented: $showDeleteAlert) {
            Button("Löschen", role: .destructive) { onDelete() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("'\(video.title)' entfernen?")
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
                Image(systemName: "video.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("VideoScheduleRow") {
    let mockVideo = Video(  // ← DEINE EXAKTEN Parameter!
        title: "Schulter Mobilisation",
        videoFileName: "shoulder.mov",
        category: .mobility,
        bodyRegion: .cervicalSpine,
        equipment: .noEquipment,
        durationSeconds: 120,
        defaultRepetitions: 3,
        defaultPauseSeconds: 30,
        loopDurationSeconds: 120,
       
        rating: 4
        // ← KEINE Extra Parameter! Nur was du schon hattest
    )
    
    let mockSchedule = VideoSchedule(
        scheduledDate: Date(),
        orderIndex: 0,
        video: mockVideo,
        customRepetitions: 4,
        customPauseSeconds: 45,
        customLoopDurationSeconds: 180
        // ← KEIN backingData! Das war falsch!
    )
    
    VideoScheduleRow(
        schedule: mockSchedule,
        video: mockVideo,
        onToggleCompletion: { print("✅ Toggle") },
        onDelete: { print("🗑️ Delete") },
        onConfig: { print("⚙️ Config") },
        onPlay: { _ in }  // ← Einfach _ !
    )
    .padding()
}
*/
struct VideoScheduleRow: View {
    let schedule: VideoSchedule
    let video: Video
    
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void
    let onConfig: () -> Void
    let onPlay: (Video) -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
  
            HStack(spacing: 16) {
 
                // ← Thumbnail mit Play-Button
                ZStack {
                    thumbnailView
                        .frame(width: 100, height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Play Button Overlay
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
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    // Stats
                    
                    HStack(spacing: 12) {
                        
                        Label("\(schedule.effectiveRepetitions)×", systemImage: "repeat")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    
                        HStack(spacing: 12) {
                            Label(schedule.formattedDuration, systemImage: "clock")
                            if schedule.effectivePauseSeconds > 0 {
                                Label("\(schedule.effectivePauseSeconds)s", systemImage: "pause")
                            }
                        }
                    
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    
                }
                
                Spacer()
                
                // ← Actions Ecke
                //      VStack(alignment: .trailing, spacing: 12) {
                VStack(spacing: 12) {
                    // Menu oben rechts
                    Menu {
                        Button("Konfigurieren") { onConfig() }
                        Button("Löschen", role: .destructive) { showDeleteAlert = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    //   Spacer()
                    
                    // Erledigt unten rechts
                    Button(action: onToggleCompletion) {
                        Image(systemName: schedule.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(schedule.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            .padding(16)
            .background(schedule.isCompleted ? Color.green.opacity(0.1) : Color(.systemBackground))
            .opacity(schedule.isCompleted ? 0.7 : 1.0)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            .alert("Löschen?", isPresented: $showDeleteAlert) {
                Button("Löschen", role: .destructive) { onDelete() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("'\(video.title)' entfernen?")
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

// Tag Helper View
struct TagView: View {
    let text: String
    let icon: String
    
    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview("VideoScheduleRow") {
    let mockVideo = Video(  // ← DEINE EXAKTEN Parameter!
        title: "Schulter Mobilisation",
        videoFileName: "shoulder.mov",
        category: .mobility,
        bodyRegion: .cervicalSpine,
        equipment: .noEquipment,
        durationSeconds: 120,
        defaultRepetitions: 3,
        defaultPauseSeconds: 30,
        loopDurationSeconds: 120,
       
        rating: 4
        // ← KEINE Extra Parameter! Nur was du schon hattest
    )
    
    let mockSchedule = VideoSchedule(
        scheduledDate: Date(),
        orderIndex: 0,
        video: mockVideo,
        customRepetitions: 4,
        customPauseSeconds: 45,
        customLoopDurationSeconds: 180
        // ← KEIN backingData! Das war falsch!
    )
    
    VideoScheduleRow(
        schedule: mockSchedule,
        video: mockVideo,
        onToggleCompletion: { print("✅ Toggle") },
        onDelete: { print("🗑️ Delete") },
        onConfig: { print("⚙️ Config") },
        onPlay: { _ in }  // ← Einfach _ !
    )
    .padding()
}
