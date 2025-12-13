//
//  CircularProgressView.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  CircularProgressView.swift
//  Agil7.0
//
//  Created by Christiane Roth on 14.10.25.
//

//
//  CircularProgressView.swift
//  Agil7.0
//
//  Circular progress indicator
//
import SwiftUI
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    LinearGradient(
                        colors: [.accent, .accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Percentage text
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("%")
                    .font(.system(size: size * 0.15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}
// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        CircularProgressView(progress: 0.35, lineWidth: 8, size: 80)
        CircularProgressView(progress: 0.75, lineWidth: 10, size: 100)
        CircularProgressView(progress: 1.0, lineWidth: 12, size: 120)
    }
    .padding()
}
