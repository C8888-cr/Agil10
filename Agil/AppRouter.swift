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
            } else if authService.isAuthenticated {  // ✅ Klarer!
                ContentView()
                    .environmentObject(AppDependencies.shared.appointmentViewModel)
                                       .environmentObject(AppDependencies.shared.calendarViewModel)
                                       .environmentObject(AppDependencies.shared.trainingViewModel)
                                       .environmentObject(AppDependencies.shared.settingsViewModel)
                                       .environmentObject(AppDependencies.shared.trainingData)
                                       .environmentObject(AppDependencies.shared.progressViewModel)
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)  // ✅ Smooth Transition
    }
}
