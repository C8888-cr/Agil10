
import Foundation

struct VideoPlayerItem: Identifiable {
    let id = UUID()
    let video: Video
    let scheduleId: UUID
    let completionStyle: SessionCompletionStyle
}
