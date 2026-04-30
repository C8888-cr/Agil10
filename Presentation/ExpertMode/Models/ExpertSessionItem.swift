
import Foundation

struct ExpertSessionItem: Identifiable {
    let id = UUID()
    let schedule: VideoSchedule
    let video: Video
    let tempoProtocol: TempoProtocol
}
