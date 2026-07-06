//
//  DayCell.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData
import AgilCore

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasSchedules: Bool
    let hasAppointments: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    
    var body: some View {
        VStack(spacing: 4) {
            // Tagnummer
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(
                    isSelected ? .white :
                    isToday ? themeManager.currentTheme.accentColor :
                    .primary
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? themeManager.currentTheme.accentColor : Color.clear)
                )
            
            // Balken
            VStack(spacing: 2) {
                if hasSchedules {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("AccentColor"))
                        .frame(height: 4)
                }
                if hasAppointments {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("Blau"))
                        .frame(height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 4)
        }
        .frame(height: 48)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
