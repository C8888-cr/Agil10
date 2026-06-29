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
                    }
                    .tabItem {
                        Label("Patienten", systemImage: "person.2.fill")
                    }
                    .tag(Tab.patients)
                    
                    // Tab 2: Übungen
                                        NavigationStack {
                                            KGGLibraryView(modelContext: modelContext, praxisId: credentials.praxisId)
                                                .environmentObject(themeManager)
                                                .environmentObject(authViewModel)
                                        }
                                        .tabItem {
                                            Label("Übungen", systemImage: "figure.strengthtraining.traditional")
                                        }
                                        .tag(Tab.library)
                    
                    // Tab 2: Einstellungen
                    NavigationStack {
                        settingsView(credentials: credentials)
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
    
    // MARK: - Settings View
    
    @ViewBuilder
    private func settingsView(credentials: KGGLoginCredentials) -> some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Praxis Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Praxis-Informationen")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            infoRow(label: "Praxis", value: credentials.praxisName)
                            infoRow(label: "Angemeldet seit", value: formatDate(credentials.loginTime))
                            if let therapist = credentials.therapistName {
                                infoRow(label: "Therapeut", value: therapist)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding(16)
                    
                    // Sicherheit
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sicherheit")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Button {
                            // TODO: Passwort ändern
                        } label: {
                            HStack {
                                Label("Admin-Passwort ändern", systemImage: "key.fill")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(.primary)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(16)
                    
                    // About
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Über")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            infoRow(label: "App", value: "Agil KGG")
                            infoRow(label: "Version", value: "1.0.0")
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding(16)
                    
                    // Logout
                    Button(role: .destructive) {
                        authViewModel.logout()
                    } label: {
                        Text("Abmelden")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .cornerRadius(12)
                    }
                    .padding(16)
                    
                    Spacer()
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    KGGMainTabView()
        .environmentObject(KGGAuthViewModel())
        .environmentObject(ThemeManager())
}
