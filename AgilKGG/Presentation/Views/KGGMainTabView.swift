//
//  KGGMainTabView.swift
//  AgilKGG
//
//  Nach Login: Tab-Navigation zwischen Patienten und Settings
//

import SwiftUI
import SwiftData
import AgilCore

struct KGGMainTabView: View {
    @EnvironmentObject var authViewModel: KGGAuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab: Tab = .patients
    
    enum Tab {
        case patients
        case kggtoday
        case library
        case settings
    }
    
    var body: some View {
        
        ZStack {
            
            if authViewModel.isLoggedIn,
               let credentials = authViewModel.currentCredentials {
                
                
                // Nach Login: Haupt-App
                TabView(selection: $selectedTab) {
                    
                    
                    // Tab 1: Patienten
                    NavigationStack {
                        KGGPatientListView(modelContext: modelContext, praxisId: credentials.praxisId)
                            .environmentObject(themeManager)
                            .frame(maxHeight: .infinity)
                    }
                    .tabItem {
                        Label("Patienten", systemImage: "person.2.fill")
                    }
                    .tag(Tab.patients)
                    
                    
                    // Tab 2: KGG heute
                    
                    NavigationStack {
                        KGGTodayView(
                            modelContext: modelContext,
                            praxisId: credentials.praxisId
                        )
                        .environmentObject(themeManager)
                        .frame(maxHeight: .infinity)
                    }
                    .tabItem {
                        Label("KGG heute", systemImage: "calendar.badge.plus")
                    }
                    .tag(Tab.kggtoday)
                    
                    // Tab 3: Übungen
                    NavigationStack {
                        KGGLibraryView(modelContext: modelContext, praxisId: credentials.praxisId
                        )
                        .environmentObject(themeManager)
                        .environmentObject(authViewModel)
                        .frame(maxHeight: .infinity)
                    }
                    .tabItem {
                        Label("Übungen", systemImage: "figure.strengthtraining.traditional")
                    }
                    .tag(Tab.library)
                    
                    // Tab 4: Einstellungen
                    NavigationStack {
                                            KGGSettingsView(credentials: credentials)
                                                .environmentObject(authViewModel)
                                                .environmentObject(themeManager)
                                                .frame(maxHeight: .infinity)
                                        }
                    .tabItem {
                        Label("Einstellungen", systemImage: "gear")
                    }
                    .tag(Tab.settings)
                }
            } else {
                // Login-Screen
                KGGLoginView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
            }
        }
    }
}
  

#Preview {
    KGGMainTabView()
        .environmentObject(KGGAuthViewModel())
        .environmentObject(ThemeManager())
}
