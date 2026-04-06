import SwiftUI

// AppRouter.swift
struct AppRouter: View {
    @EnvironmentObject var authService: AuthService  // ← noch drin für isLoading
    @EnvironmentObject var session: SessionManager   // ← NEU
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView()
            } else if session.isAuthenticated {  // ← session statt authService
                ContentView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: session.isAuthenticated)
    }
}
