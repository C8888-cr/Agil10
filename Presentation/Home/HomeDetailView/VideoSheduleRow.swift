
import SwiftUI
import SwiftData
import AVKit

struct VideoScheduleRow: View {
    let schedule: VideoSchedule
    let video: Video
    let workoutModus: WorkoutModus

    var onToggleCompletion: (() -> Void)? = nil
    let onDelete: () -> Void
    let onConfig: () -> Void
    let onPlay: (Video) -> Void
    var onRate: ((Int) -> Void)? = nil

    @State private var showDeleteAlert = false
    @State private var showRatingSheet = false
    @State private var showLeftActions = false
    
    @State private var offset: CGFloat = 0
    @State private var rowWidth: CGFloat = 0
    @State private var dragDirection: DragDirection? = nil
    @State private var hasTriggeredHaptic = false
    
    private let actionAreaRatio: CGFloat = 0.5
    private let deleteThresholdRatio: CGFloat = 0.75
    
    enum DragDirection { case horizontal, vertical }
    
    private var actionAreaWidth: CGFloat { rowWidth * actionAreaRatio }
    private var deleteThreshold: CGFloat { rowWidth * deleteThresholdRatio }
    
    private var trashWidth: CGFloat {
        let absOffset = abs(offset)
        if absOffset <= actionAreaWidth {
            return actionAreaWidth / 2
        } else {
            let extraWidth = absOffset - actionAreaWidth
            return (actionAreaWidth / 2) + extraWidth
        }
    }
    
    private var ellipsisWidth: CGFloat {
        let absOffset = abs(offset)
        if absOffset <= actionAreaWidth {
            return actionAreaWidth / 2
        } else {
            let extraWidth = absOffset - actionAreaWidth
            return max(0, (actionAreaWidth / 2) - extraWidth)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .trailing) {
                
                // MARK: - Action-Bereich (rechts hinter der Row)
                if offset < 0 {
                    HStack(spacing: 0) {
                        // Pünktchen-Slot — Icon ODER Action-Buttons
                        if ellipsisWidth > 8 {
                            ZStack {
                                if showLeftActions {
                                    // 3 Buttons mittig, etwas kleiner als Card
                                    VStack(spacing: 10) {
                                        if onToggleCompletion != nil {
                                            actionButton(icon: "checkmark.circle", color: .green) {
                                                onToggleCompletion?()
                                                close()
                                            }
                                        }
                                        actionButton(
                                            icon: "gearshape",
                                            color: .blue,
                                            disabled: schedule.isCompleted
                                        ) {
                                            if !schedule.isCompleted { onConfig(); close() }
                                        }
                                        if onRate != nil {
                                            actionButton(icon: "star", color: .orange) {
                                                showRatingSheet = true
                                                close()
                                            }
                                        }
                                    }
                                } else {
                                    // Pünktchen-Icon
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            showLeftActions = true
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .background(.gray.opacity(0.7))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(width: ellipsisWidth, height: 120)
                        }
                        
                        // Trash-Button
                        Button {
                            showDeleteAlert = true
                        } label: {
                            ZStack {
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 16,
                                    topTrailingRadius: 16
                                )
                                .fill(Color.red.opacity(0.85))
                                
                                Image(systemName: "trash.fill")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: trashWidth, height: 120)
                        }
                        .buttonStyle(.plain)
                        .disabled(schedule.isCompleted)
                    }
                }

                // MARK: - Row Content (verschiebbar)
                rowContent
                    .offset(x: offset)
                    .gesture(dragGesture)
            }
            .onAppear {
                rowWidth = geo.size.width
            }
            .onChange(of: geo.size.width) { _, newWidth in
                rowWidth = newWidth
            }
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
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                if dragDirection == nil {
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)
                    if dx > dy && dx > 10 {
                        dragDirection = .horizontal
                    } else if dy > dx {
                        dragDirection = .vertical
                        return
                    }
                }
                
                guard dragDirection == .horizontal else { return }
                
                let drag = value.translation.width
                
                if drag < 0 {
                    if schedule.isCompleted {
                        offset = max(drag, -actionAreaWidth)
                    } else {
                        offset = max(drag, -rowWidth)
                    }
                    showLeftActions = false
                    
                    if !schedule.isCompleted {
                        let triggered = abs(offset) >= deleteThreshold
                        if triggered != hasTriggeredHaptic {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            hasTriggeredHaptic = triggered
                        }
                    }
                } else {
                    offset = min(drag, 0)
                }
            }
            .onEnded { value in
                defer {
                    dragDirection = nil
                    hasTriggeredHaptic = false
                }
                guard dragDirection == .horizontal else { return }
                
                if !schedule.isCompleted && abs(offset) >= deleteThreshold {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    withAnimation(.easeIn(duration: 0.2)) {
                        offset = -rowWidth
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDelete()
                    }
                    return
                }
                
                withAnimation(.spring(response: 0.3)) {
                    if abs(offset) > actionAreaWidth / 2 {
                        offset = -actionAreaWidth
                    } else {
                        close()
                    }
                }
            }
    }
    
    // MARK: - Row Content
    
    private var rowContent: some View {
        HStack(spacing: 0) {
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

            VStack(alignment: .leading, spacing: 10) {
                Text(video.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                VStack(alignment: .leading, spacing: 4) {
                                    let usesPill = (workoutModus == .expert || workoutModus == .mobility)
                                        && schedule.isExpertDynamicCapable
                                    if usesPill {
                                        MetaChip(label: "Sätze", value: "\(schedule.activeSets(modus: workoutModus)) × \(schedule.activeReps(modus: workoutModus))")
                                        MetaChip(label: "Dauer", value: schedule.formattedDuration(modus: workoutModus))
                                        let pause = schedule.activePauseSeconds(modus: workoutModus)
                                        if pause > 0 {
                                            MetaChip(label: "Pause", value: "\(pause)s")
                                        }
                                        if let weight = schedule.activeWeightKg(modus: workoutModus) {
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
    
    // MARK: - Helpers
    
    private struct MetaChip: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack(spacing: 6) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .leading)
                
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
    
    private func close() {
        withAnimation(.spring(response: 0.3)) {
            offset = 0
            showLeftActions = false
        }
    }
    
    private func actionButton(
        icon: String,
        color: Color,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color.opacity(disabled ? 0.3 : 0.85), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
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
