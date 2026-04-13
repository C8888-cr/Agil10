//
//  DayProgressBar.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData



struct DayProgressBar: View {
    let dayName: String
    let progress: Double
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            // Balken
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 80)
                
                // Progress
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: progress > 0 ? [.accent, .accent.opacity(0.7)] : [.gray.opacity(0.3)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: max(4, progress * 80))
                    .animation(.spring(response: 0.6), value: progress)
            }
            
            // Tag Label
            Text(dayName)
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .accent : .secondary)
            
            // Heute Indikator
            if isToday {
                Circle()
                    .fill(Color.accent)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
