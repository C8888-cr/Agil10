//
//  VideoPreviewHelper.swift
//  Agil
//
//  Created by Christiane Roth on 01.12.25.
//

import SwiftUI
import SwiftData

// MARK: - Preview Helpers
extension Video {
    static var previewMobility: Video {
        Video(
            title: "Schulter Mobilisation",
            videoFileName: "shoulder_mobility.mp4",
            category: .mobility,
            bodyRegion: .cervicalSpine,
            equipment: .noEquipment,
            durationSeconds: 420,
            fileSizeBytes: 15_000_000,
            defaultRepetitions: 1,
            defaultPauseSeconds: 30,
            loopDurationSeconds: 420,
      
            rating: 3
        )
    }
    
    static var previewStrength: Video {
        Video(
            title: "Krafttraining Rücken",
            videoFileName: "back_strength.mp4",
            category: .strength,
            bodyRegion: .back,
            equipment: .weights,
            durationSeconds: 600,
            fileSizeBytes: 30_000_000,
            defaultRepetitions: 3,
            defaultPauseSeconds: 60,
            loopDurationSeconds: 600,
      
            rating: 5
        )
    }
    
    static var previewStretching: Video {
        Video(
            title: "LWS Dehnung",
            videoFileName: "lws_stretch.mp4",
            category: .stretching,
            bodyRegion: .lumbarSpine,
            equipment: .bodyweight,
            durationSeconds: 300,
            fileSizeBytes: 12_000_000,
            defaultRepetitions: 2,
            defaultPauseSeconds: 45,
            loopDurationSeconds: 300,
          
            rating: 6
        )
    }
    
    static var previewCardio: Video {
        Video(
            title: "Ausdauer Training",
            videoFileName: "cardio_fullbody.mp4",
            category: .cardio,
            bodyRegion: .fullBody,
            equipment: .noEquipment,
            durationSeconds: 900,
            fileSizeBytes: 45_000_000,
            defaultRepetitions: 1,
            defaultPauseSeconds: 0,
            loopDurationSeconds: 900,
       
            rating: 2
        )
    }
    
    static var previewWarmup: Video {
        Video(
            title: "Aufwärmen Ganzkörper",
            videoFileName: "warmup.mp4",
            category: .warmup,
            bodyRegion: .fullBody,
            equipment: .noEquipment,
            durationSeconds: 300,
            fileSizeBytes: 10_000_000,
            defaultRepetitions: 1,
            defaultPauseSeconds: 30,
            loopDurationSeconds: 300,
           
            rating: 1
        )
    }
}


