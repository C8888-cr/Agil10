//
//  ThemeManager.swift
//  Agil10.0
//
//  Created by Christiane Roth on 04.05.26.
//

import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            print("🎨 Theme didSet: \(oldValue.rawValue) → \(currentTheme.rawValue)")
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.pink.rawValue
        self.currentTheme = AppTheme(rawValue: saved) ?? .pink
        print("🎨 ThemeManager INIT mit Theme: \(currentTheme.rawValue)")   // ← wichtig!
    }
}

