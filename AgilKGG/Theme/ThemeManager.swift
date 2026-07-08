//
//  ThemeManager.swift
//  Agil10
//
//  Created by Christiane Roth on 07.07.26.
//


//
//  ThemeManager.swift
//  Agil10
//
//  Created by Christiane Roth on 07.07.26.
//


//
//  ThemeManager.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.07.26.
//



//
//  ThemeManager.swift
//  Agil10.0
//
//  Created by Christiane Roth on 04.05.26.
//

import SwiftUI
import Combine

public class ThemeManager: ObservableObject {
    @Published public var currentTheme: AppTheme {
        didSet {
            print("🎨 Theme didSet: \(oldValue.rawValue) → \(currentTheme.rawValue)")
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    public init() {
        let saved = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.pink.rawValue
        self.currentTheme = AppTheme(rawValue: saved) ?? .pink
        print("🎨 ThemeManager INIT mit Theme: \(currentTheme.rawValue)")   // ← wichtig!
    }
}

