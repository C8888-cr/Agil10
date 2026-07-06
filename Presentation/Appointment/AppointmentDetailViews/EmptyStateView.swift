//
//  EmptyStateView.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  EmptyStateView.swift
//  Agil7.0
//
//  Created by Christiane Roth on 08.10.25.
//
import SwiftUI
import SwiftData
import AgilCore


// MARK: - Empty State
struct EmptyStateView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    let showingManualEntry: () -> Void
    let showingEmailImport: () -> Void
    
    var body: some View {
      
        
        VStack(spacing: 24) {
            Image(systemName:
                    "calendar.badge.exclamationmark")
            .font(.system(size: 64))
            .foregroundColor(.secondary.opacity(0.5))
            
            Text("Keine Termine")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Trage einen Termin ein oder importiere\nihn aus einer Email")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button(action: showingManualEntry) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                        Text("Manuell")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 120, height: 100)
                    .background(
                        LinearGradient(
                            colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: themeManager.currentTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Button(action: showingEmailImport) {
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.title)
                        Text("Email")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 120, height: 100)
                    .background(
                        LinearGradient(
                            colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: themeManager.currentTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding()
    }
}
// MARK: - Preview
#Preview {
    EmptyStateView(
        showingManualEntry: {
            print("Manuell getappt")
        },
        showingEmailImport: {
            print("Email getappt")
        }
    )
}
