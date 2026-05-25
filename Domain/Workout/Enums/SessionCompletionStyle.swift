//
//  SessionCompletionStyle.swift
//  Agil10.0
//
//  Created by Christiane Roth on 25.05.26.
//


//
//  SessionCompletionStyle.swift
//  Agil
//
//  Legt fest, welches Abschluss-Sheet nach einer Trainingssession erscheint.
//  Entkoppelt das ViewModel vom konkreten Modus (Single Source of Truth
//  für das Completion-Verhalten).
//

import Foundation

enum SessionCompletionStyle: String, Codable {
    /// Sterne-Bewertung (Expertenmodus): Wie war das Training?
    case starRating
    /// Stufenlose Feedback-Leiste mit Farbverlauf (Mobility-Modus).
    case feedbackScale
}