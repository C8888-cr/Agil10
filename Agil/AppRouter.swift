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
            } else if let user = appState.currentUser {
                ContentView(user: user)  // ← TABS mit User!
            } else {
                LoginView(authService: AppDependencies.shared.authService)
            }
        }
    }
}

