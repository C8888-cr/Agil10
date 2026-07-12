//
//  ThemePickerSection.swift
//  Agil10.0
//
//  Created by Christiane Roth on 04.05.26.
//

import SwiftUI
import AgilCore


struct ThemePickerSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Section("Farbe") {
            ForEach(AppTheme.allCases) { theme in
                Button {
                    themeManager.currentTheme = theme
                } label: {
                    HStack {
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 24, height: 24)
                        Text(theme.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        if themeManager.currentTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
#Preview {
    ThemePickerSection()
        .environmentObject(ThemeManager())
}
