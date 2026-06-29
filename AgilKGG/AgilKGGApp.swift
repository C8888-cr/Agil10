//
//  AgilKGGApp.swift
//  AgilKGG
//
//  Entry Point der Therapeuten-App mit Login-Flow
//

import SwiftUI
import SwiftData
import AgilCore

@main
struct AgilKGGApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var authViewModel = KGGAuthViewModel()
    
    let modelContainer: ModelContainer
    
    init() {
        // ModelContainer Setup
        do {
            modelContainer = try ModelContainer(
                for: KGGPatient.self,
                KGGExercise.self,
                KGGExerciseHistory.self,
                KGGWarmup.self,
                KGGLibraryExercise.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }
   
    var body: some Scene {
        WindowGroup {
            if authViewModel.isLoggedIn {
                // Nach Login: Haupt-App
                KGGMainTabView()
                    .environment(\.modelContext, modelContainer.mainContext)
                    .environmentObject(themeManager)
                    .environmentObject(authViewModel)
                    .tint(themeManager.currentTheme.accentColor)
            } else {
                // Login-Screen
                KGGLoginView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
                    .tint(themeManager.currentTheme.accentColor)
            }
        }
    }
 
    
   
}
