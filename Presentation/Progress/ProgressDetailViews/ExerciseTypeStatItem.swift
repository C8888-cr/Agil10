//
//  ExerciseTypeStatItem.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//

import SwiftUI
import SwiftData

struct ExerciseTypeStatItem: View {
    let category: ExerciseCategory
    let minutes: Int
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // Icon mit Gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [category.color, category.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                // Checkmark wenn erledigt
                if isCompleted {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 18, height: 18)
                                )
                        }
                        Spacer()
                    }
                    .frame(width: 50, height: 50)
                }
            }
            
            // Category Name
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            // Dauer
            Text("\(minutes) Min")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(category.color.opacity(0.1))
        .cornerRadius(12)
    }
}
