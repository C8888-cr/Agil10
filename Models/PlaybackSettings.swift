//
//  PlaybackSettings.swift
//  Agil
//
//  Created by Christiane Roth on 26.11.25.
//


//
//  PlaybackSettings.swift
//  Agil7.0
//
//  Created by Christiane Roth on 10.10.25.
//

//
//  PlaybackSettings.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.01.25.
//
import Foundation
/// Wiedergabe-Einstellungen
//
//  PlaybackSettings.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.01.25.
//
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
/// Video-Fortschritt
struct VideoProgress {
    var currentTime: TimeInterval
    var duration: TimeInterval
    var bufferedTime: TimeInterval
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var remainingTime: TimeInterval {
        duration - currentTime
    }
    
    var isNearEnd: Bool {
        remainingTime < 5.0
    }
    
    static var zero: VideoProgress {
        VideoProgress(currentTime: 0, duration: 0, bufferedTime: 0)
    }
}
