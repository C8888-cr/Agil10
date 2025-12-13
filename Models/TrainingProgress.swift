//
//  TrainingProgress.swift
//  Agil
//
//  Created by Christiane Roth on 26.11.25.
//


//
//  TrainingProgress.swift
//  Agil7.0
//
//  Created by Christiane Roth on 10.10.25.
//

//
//  TrainingProgress.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.01.25.
//
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
