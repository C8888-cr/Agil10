
import Foundation

struct PlaybackSettings {
    var mode: PlaybackMode
    var speed: PlaybackSpeed
    var volume: Float
    var isMuted: Bool
    
    // Training Mode Settings
    var repetitions: Int
    var pauseSeconds: Int
    var loopDurationSeconds: Int 
    
    init(
        mode: PlaybackMode = .normal,
        speed: PlaybackSpeed = .normal,
        repetitions: Int = 1,
        pauseSeconds: Int = 30,
        volume: Float = 1.0,
        isMuted: Bool = false,
        loopDurationSeconds: Int = 0
    ) {
        self.mode = mode
        self.speed = speed
        self.repetitions = repetitions
        self.pauseSeconds = pauseSeconds
        self.volume = volume
        self.isMuted = isMuted
        self.loopDurationSeconds = loopDurationSeconds
    }
}

