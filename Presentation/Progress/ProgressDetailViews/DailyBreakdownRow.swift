//
//  DailyBreakdownRow.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData
import AgilCore


struct DailyBreakdownRow: View {
    let dayName: String
    let shortName: String
    let progress: Double
    let watchedMinutes: Int
    let targetMinutes: Int
    let isToday: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Day Circle
            ZStack {
                Circle()
                    .fill(isToday ? themeManager.currentTheme.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(shortName)
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundColor(isToday ? themeManager.currentTheme.accentColor : .secondary)
            }
            
            // Day Name
            Text(dayName)
                .font(.subheadline)
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundColor(isToday ? .primary : .secondary)
                .frame(width: 100, alignment: .leading)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            
            // Minutes
            Text("\(watchedMinutes)/\(targetMinutes)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(progress >= 1.0 ? .green : .secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}
