import SwiftUI
import UniformTypeIdentifiers

enum DropPosition {
    case above
    case below
}

struct ScheduleDropIndicator: Equatable {
    let targetId: UUID
    let position: DropPosition
}

struct ScheduleDropDelegate: DropDelegate {
    let target: VideoSchedule
    @Binding var draggedScheduleId: UUID?
    @Binding var dropIndicator: ScheduleDropIndicator?
    let onMove: (UUID, VideoSchedule, DropPosition) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggedId = draggedScheduleId, draggedId != target.id else { return }
        updateIndicator(info: info)
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateIndicator(info: info)
        return DropProposal(operation: .move)
    }
    
    func dropExited(info: DropInfo) {
        if dropIndicator?.targetId == target.id {
            dropIndicator = nil
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedId = draggedScheduleId, draggedId != target.id else { return false }
        let position = dropIndicator?.position ?? .above
        defer {
            draggedScheduleId = nil
            dropIndicator = nil
        }
        onMove(draggedId, target, position)
        return true
    }
    
    private func updateIndicator(info: DropInfo) {
        // info.location.y liegt relativ zur Row
        // Wenn Finger in oberer Hälfte → above, sonst below
        // Wir wissen leider nicht die Row-Höhe exakt, aber bei ~120pt ist 60 die Mitte
        let position: DropPosition = info.location.y < 60 ? .above : .below
        dropIndicator = ScheduleDropIndicator(targetId: target.id, position: position)
    }
}
