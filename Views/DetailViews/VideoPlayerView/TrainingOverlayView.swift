//
//  TrainingOverlayView.swift
//  Agil
//
//  Created by Christiane Roth on 26.11.25.
//
/*

//
//  TrainingOverlayView.swift
//  Agil7.0
//
//  Created by Christiane Roth on 10.10.25.
//

//
//  TrainingOverlayView.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.01.25.
//
import SwiftUI
struct TrainingOverlayView: View {
    let progress: TrainingProgress
    
    var body: some View {
        VStack {
            Spacer()
            
            if progress.isInPause {
                pauseView
            } else {
                repetitionView
            }
        }
        .padding()
    }
    
    // MARK: - Repetition View
    
    private var repetitionView: some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.title2)
            
            Text("Wiederholung \(progress.currentRepetition) / \(progress.totalRepetitions)")
                .font(.headline)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.8))
        )
        .shadow(color: .black.opacity(0.3), radius: 8)
    }
    
    // MARK: - Pause View
    
    private var pauseView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white)
            
            Text("Pause")
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(progress.remainingPauseSeconds)s")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
            
            Text("Bereite dich auf die nächste Wiederholung vor")
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
        )
        .shadow(color: .black.opacity(0.3), radius: 12)
    }
}
// MARK: - Preview
#Preview("Training - Active") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TrainingOverlayView(
            progress: TrainingProgress(
                totalRepetitions: 3,
                currentRepetition: 2,
                isInPause: false,
                remainingPauseSeconds: 0
            )
        )
    }
}
#Preview("Training - Pause") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TrainingOverlayView(
            progress: TrainingProgress(
                totalRepetitions: 3,
                currentRepetition: 2,
                isInPause: true,
                remainingPauseSeconds: 25
            )
        )
    }
}
*/
