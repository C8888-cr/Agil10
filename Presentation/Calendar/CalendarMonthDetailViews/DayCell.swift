//
//  DayCell.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasSchedules: Bool
    let hasAppointments: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Tagnummer
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(
                    isSelected ? .white :
                    isToday ? .accent :
                    .primary
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accent : Color.clear)
                )
            
            // Balken
            VStack(spacing: 2) {
                if hasSchedules {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accent)
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
