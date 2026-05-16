//
//  ProfileSettingsView.swift
//  Agil10.0
//
//  App-Einstellungen, die aus dem Profil heraus geöffnet werden.
//  Nicht zu verwechseln mit der bestehenden SettingsView (Trainings-Reminder).
//

import SwiftUI
import SwiftData

struct ProfileSettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager

    @Query var users: [User]

    @State private var showPrivacyPolicy = false

    private var currentUser: User? {
        guard let userId = session.currentUser?.id else { return nil }
        return users.first { $0.id == userId }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Darstellung
                        InfoCard {
                            HStack {
                                Label {
                                    Text("Farbe").foregroundStyle(.secondary)
                                } icon: {
                                    Image(systemName: "paintpalette.fill")
                                        .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.7))
                                }
                                Spacer()

                                HStack(spacing: 16) {
                                    ForEach(AppTheme.allCases) { theme in
                                        Button {
                                            themeManager.currentTheme = theme
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(theme.accentColor)
                                                    .frame(width: 36, height: 36)

                                                if themeManager.currentTheme == theme {
                                                    Circle()
                                                        .stroke(Color.primary, lineWidth: 2)
                                                        .frame(width: 44, height: 44)

                                                    Image(systemName: "checkmark")
                                                        .foregroundStyle(.white)
                                                        .font(.system(size: 14, weight: .bold))
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // MARK: - Training / Expertenmodus
                        if let user = currentUser, user.preferences != nil {
                            InfoCard {
                                VStack(spacing: 0) {
                                    HStack {
                                        Label {
                                            Text("Expertenmodus").foregroundStyle(.secondary)
                                        } icon: {
                                            Image(systemName: "dumbbell.fill")
                                                .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.7))
                                        }
                                        Spacer()
                                        Toggle("", isOn: Binding(
                                            get: { settingsVM.preferences.expertModeEnabled },
                                            set: { newValue in
                                                settingsVM.preferences.expertModeEnabled = newValue
                                                try? settingsVM.modelContext.save()
                                            }
                                        ))
                                        .labelsHidden()
                                        .tint(themeManager.currentTheme.accentColor)
                                    }

                                    if settingsVM.preferences.expertModeEnabled {
                                        Text("Bei Krafttraining wird der Trainingsmodus mit Tempo-Vorgabe und Gewichts-Tracking angezeigt.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.top, 8)
                                    }
                                }
                            }
                        }

                   

                     
                    }
                    .padding(.top)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
