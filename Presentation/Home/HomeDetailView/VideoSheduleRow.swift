/*
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
    let onRate: (Int) -> Void
    
    @State private var showDeleteAlert = false
    @State private var showRatingSheet = false
    
    var body: some View {

            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 8) {
                    // 1. Thumbnail with Play overlay
                    ZStack {
                        thumbnailView
                            .frame(width: 160)
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
                            Button("Rating") { showRatingSheet = true }
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
                .frame(height: 90)
                .padding(.vertical, 16)
                .padding(.trailing, 16)
                
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
                .sheet(isPresented: $showRatingSheet) {  // ← NEU
                    VideoRatingSheet(videoTitle: video.title) { rating in
                        onRate(rating)
                    }
                    .presentationDetents([.medium])
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
                    .frame(maxHeight: .infinity)
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
            onToggleCompletion: { },
            onDelete: { },
            onConfig: { },
            onPlay: { _ in },
            onRate: { _ in }
        )
        VideoScheduleRow(
            schedule: createMockSchedule(completed: true, rating: 5),
            video: createMockVideo(title: "Rücken Dehnung"),
            onToggleCompletion: { },
            onDelete: { },
            onConfig: { },
            onPlay: { _ in },
            onRate: { _ in }
        )
    }
    .padding()
}
*/


import SwiftUI
import SwiftData
import AVKit

struct VideoScheduleRow: View {
    let schedule: VideoSchedule
    let video: Video
    let expertModeEnabled: Bool

    var onToggleCompletion: (() -> Void)? = nil
    let onDelete: () -> Void
    let onConfig: () -> Void
    let onPlay: (Video) -> Void
    var onRate: ((Int) -> Void)? = nil

    @State private var showDeleteAlert = false
    @State private var showRatingSheet = false
    @State private var offset: CGFloat = 0
    @State private var showLeftActions = false

    private let leftWidth: CGFloat = 160
    private let rightWidth: CGFloat = 80
    
    @GestureState private var dragState: CGSize = .zero
    @State private var isHorizontalDrag: Bool? = nil
    
   
    @State private var dragDirection: DragDirection? = nil

    enum DragDirection { case horizontal, vertical }

    var body: some View {
        ZStack(alignment: .leading) {

            if offset > 0 {
                // MARK: - Linke Aktionen
                HStack(spacing: 0) {
                    if showLeftActions {
                        // Aufgeklappt: einzelne Buttons
                        HStack(spacing: 8) {
                            if onToggleCompletion != nil {
                                actionButton(icon: "checkmark.circle", color: .green) {
                                    onToggleCompletion?()
                                    close()
                                }
                            }
                            actionButton(icon: "gearshape", color: .blue) { onConfig(); close() }
                            if onRate != nil {
                                actionButton(icon: "star", color: .orange) { showRatingSheet = true; close() }
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(width: leftWidth)
                        .frame(maxHeight: .infinity)
              
                    } else {
                        // Zugeklappt: Pünktchen-Button
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showLeftActions = true
                                offset = leftWidth
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: leftWidth, height: 60)
                                .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                    
                                .padding(.vertical, 30)
                        }
                     
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            
            
            // MARK: - Rechte Aktion (Löschen)
            if offset < 0 {
                HStack {
                    Spacer()
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash.fill")
                                                   .font(.title3.weight(.semibold))
                                                   .foregroundStyle(.white)
                                                   .frame(width: 44, height: 44)
                                                   .glassEffect(in: Circle())
                                                   .background(Color.red.opacity(0.8), in: Circle())
                                           }
                                           .buttonStyle(.plain)
                                           .padding(.trailing, 18)
                }
            }
            // MARK: - Row Content
            rowContent
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 15)  // ← wichtig: höher!
                        .onChanged { value in
                            // Richtung EINMAL festlegen
                            if dragDirection == nil {
                                let dx = abs(value.translation.width)
                                let dy = abs(value.translation.height)
                                // Nur wenn deutlich horizontal → übernehmen
                                if dx > dy && dx > 10 {
                                    dragDirection = .horizontal
                                } else if dy > dx {
                                    dragDirection = .vertical
                                    return
                                }
                            }
                            
                            guard dragDirection == .horizontal else { return }
                            
                            let drag = value.translation.width
                            if drag > 0 {
                                offset = min(drag, leftWidth)
                            } else {
                                offset = max(drag, -rightWidth)
                                showLeftActions = false
                            }
                        }
                        .onEnded { value in
                            defer { dragDirection = nil }
                            guard dragDirection == .horizontal else { return }
                            
                            let drag = value.translation.width
                            withAnimation(.spring(response: 0.3)) {
                                if drag > leftWidth / 2 {
                                    offset = leftWidth
                                    showLeftActions = true
                                } else if drag < -rightWidth / 2 {
                                    offset = -rightWidth
                                    showLeftActions = false
                                } else {
                                    close()
                                }
                            }
                        }
                )
        }
        .frame(height: 120)
           .contentShape(RoundedRectangle(cornerRadius: 16))
           .clipShape(RoundedRectangle(cornerRadius: 16))
        .alert("Löschen?", isPresented: $showDeleteAlert) {
            Button("Löschen", role: .destructive) { onDelete() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("'\(video.title)' entfernen?")
        }
        .sheet(isPresented: $showRatingSheet) {
            VideoRatingSheet(videoTitle: video.title) { rating in onRate?(rating) }
                .presentationDetents([.medium])
        }
    }
// MARK: RowContent
    private var rowContent: some View {
        HStack(spacing: 0) {
            // Thumbnail – wächst mit der Card mit
            ZStack {
                thumbnailView
                    .frame(width: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: { onPlay(video) }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 48, height: 48)
                        Image(systemName: "play.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
            }

            // Text-Block
            VStack(alignment: .leading, spacing: 10) {
                // Titel
                Text(video.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                // Meta – einheitlich als Chips
                VStack(alignment: .leading, spacing: 4) {
                    if expertModeEnabled && schedule.isExpertDynamicCapable {
                        MetaChip(label: "Sätze", value: "\(schedule.effectiveSets) × \(schedule.effectiveRepsPerSet)")
                        MetaChip(label: "Dauer", value: schedule.formattedDuration(expertModeEnabled: true))
                        if schedule.effectiveExpertPauseSeconds > 0 {
                            MetaChip(label: "Pause", value: "\(schedule.effectiveExpertPauseSeconds)s")
                        }
                        if let weight = schedule.weightKg {
                            MetaChip(label: "Gewicht", value: "\(weight) kg")
                        }
                    } else {
                        MetaChip(label: "Wdh", value: "\(schedule.effectiveRepetitions)")
                        MetaChip(label: "Dauer", value: schedule.formattedDuration)
                        if schedule.effectivePauseSeconds > 0 {
                            MetaChip(label: "Pause", value: "\(schedule.effectivePauseSeconds)s")
                        }
                    }
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: 120)
        .background(schedule.isCompleted ? Color.green.opacity(0.1) : Color(.systemBackground))
        .opacity(schedule.isCompleted ? 0.7 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .overlay(alignment: .bottomTrailing) {
            if let rating = schedule.rating {
                Text(emoji(for: rating))
                    .font(.title3)
                    .padding(10)
            }
        }
    }

    // MARK: - Meta Chip
    private struct MetaChip: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack(spacing: 6) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .leading)  // ← fixe Breite = Ausrichtung
                
                Text(value)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
            }
        }
    }

    private func emoji(for rating: Int) -> String {
        switch rating {
        case 1: return "😣"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😀"
        case 5: return "🤩"
        default: return ""
        }
    }
    // MARK: - Helpers
    private func close() {
        withAnimation(.spring(response: 0.3)) {
            offset = 0
            showLeftActions = false
        }
    }

    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .glassEffect(in: Circle())
                .background(color.opacity(0.8), in: Circle())
        }
    }

    private var thumbnailView: some View {
        Group {
            if let thumbnailFileName = video.thumbnailFileName,
               let thumbnail = ThumbnailGeneratorService.shared.loadThumbnail(fileName: thumbnailFileName) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: .infinity)
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
            video: createMockVideo(), expertModeEnabled: true,
            onToggleCompletion: { },
            onDelete: { },
            onConfig: { },
            onPlay: { _ in },
            onRate: { _ in }
        )
        VideoScheduleRow(
            schedule: createMockSchedule(completed: true, rating: 5),
            video: createMockVideo(title: "Rücken Dehnung"), expertModeEnabled: false,
            onToggleCompletion: { },
            onDelete: { },
            onConfig: { },
            onPlay: { _ in },
            onRate: { _ in }
        )
    }
    .padding()
}
