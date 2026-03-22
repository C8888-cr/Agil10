//
//  AppRouter.swift
//  Agil10.0
//
//  Created by Christiane Roth on 16.12.25.
//

import SwiftUI
import SwiftData

struct AppRouter: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView()
            } else if authService.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}
