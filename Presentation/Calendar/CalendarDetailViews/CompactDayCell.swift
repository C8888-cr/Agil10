//
//  CompactDayCell.swift
//  Agil
//
//  Created by Christiane Roth on 23.11.25.
//

import SwiftUI
struct CompactDayCell: View {
    // MARK: - Properties
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasAppointment: Bool
    @EnvironmentObject var themeManager: ThemeManager
  //  let hasExercises: Bool
  //  let exerciseProgress: Double
    
    private let calendar = Calendar.current
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 4) {
            Text(Date.shortDayFormatter.string(from: date).prefix(2).uppercased())
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(textColor)
            
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(textColor)
            
            indicatorView
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isToday && !isSelected ? 2 : 0)
        )
    }
    
    // MARK: - Subviews
    private var indicatorView: some View {
        HStack(spacing: 3) {
            if hasAppointment {
                Circle()
                    .fill(themeManager.currentTheme.accentColor)
                    .frame(width: 5, height: 5)
            }
            
       /*     if hasExercises {
                Circle()
                    .fill(exerciseIndicatorColor)
                    .frame(width: 5, height: 5)
            }*/
        }
        .frame(height: 8)
    }
    
    // MARK: - Computed Properties
/*    private var exerciseIndicatorColor: Color {
        if exerciseProgress >= 1.0 {
            return .green
        } else if exerciseProgress > 0 {
            return .orange
        } else {
            return .blue
        }
    }*/
    
    private var textColor: Color {
        isSelected ? .white : .primary
    }
    
    private var backgroundColor: Color {
        isSelected ? themeManager.currentTheme.accentColor : Color(.secondarySystemGroupedBackground)
    }
    
    private var borderColor: Color {
        isToday ? themeManager.currentTheme.accentColor : .clear
    }
}
// MARK: - Preview
struct CompactDayCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Selected + Today
            CompactDayCell(
                date: Date(),
                isSelected: true,
                isToday: true,
                hasAppointment: true,
             //   hasExercises: true,
             //   exerciseProgress: 0.5
            )
            
            // Not selected + Has appointment
            CompactDayCell(
                date: Date(),
                isSelected: false,
                isToday: false,
                hasAppointment: true,
              //  hasExercises: false,
             //   exerciseProgress: 0
            )
            
            // Completed exercises
            CompactDayCell(
                date: Date(),
                isSelected: false,
                isToday: false,
                hasAppointment: false,
            //    hasExercises: true,
            //    exerciseProgress: 1.0
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
