//
//  AppRouter.swift
//  Agil10.0
//
//  Created by Christiane Roth on 16.12.25.
//

import SwiftUI
import SwiftData

struct AppRouter: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoading {
                LoadingView()
            } else if appState.isAuthenticated {  // ← NEU!
                ContentView()
            } else {
                LoginView(authService: AppDependencies.shared.authService)
            }
        }
    }
}


