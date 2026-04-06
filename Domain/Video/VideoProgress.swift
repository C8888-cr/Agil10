//
//  VideoProgress.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//
import Foundation

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
