
import Foundation

struct TrainingProgress {
    var totalRepetitions: Int
    var currentRepetition: Int
    var isInPause: Bool
    var remainingPauseSeconds: Int
    
    init(
        totalRepetitions: Int,
        currentRepetition: Int = 1,
        isInPause: Bool = false,
        remainingPauseSeconds: Int = 0
    ) {
        self.totalRepetitions = totalRepetitions
        self.currentRepetition = currentRepetition
        self.isInPause = isInPause
        self.remainingPauseSeconds = remainingPauseSeconds
    }
}
