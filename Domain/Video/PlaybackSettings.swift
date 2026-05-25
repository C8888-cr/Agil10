
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
        repetitions: Int = PlaybackDefaults.repetitions,
        pauseSeconds: Int = PlaybackDefaults.pauseSeconds,
        volume: Float = 1.0,
        isMuted: Bool = false,
        loopDurationSeconds: Int = PlaybackDefaults.loopDurationSeconds
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

