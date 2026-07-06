//
//  AppTheme.swift
//  Agil10.0
//
//  Created by Christiane Roth on 27.06.26.
//


//
//  AppTheme.swift
//  Agil10.0
//
//  Created by Christiane Roth on 04.05.26.
//

import SwiftUI

public enum AppTheme: String, CaseIterable, Identifiable {
    case pink, blue, yellow
    
    public var id: String { rawValue }
    
    public var accentColor: Color {
        switch self {
        case .pink:   return Color("AccentColor")
        case .blue:   return Color("Blau")
        case .yellow: return Color("Gelb")
        }
    }
    
    public var displayName: String {
        switch self {
        case .pink:   return "Pink"
        case .blue:   return "Blau"
        case .yellow: return "Gelb"
        }
    }
}
