//
//  ProfileSettingsView.swift
//  Agil10.0
//
//  App-Einstellungen, die aus dem Profil heraus geöffnet werden.
//  Nicht zu verwechseln mit der bestehenden SettingsView (Trainings-Reminder).
//

import SwiftUI
import SwiftData
import AgilCore


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

                        // MARK: - Training / Trainingsmodus
                        if let user = currentUser, user.preferences != nil {
                            InfoCard {
                                VStack(spacing: 0) {
                                    HStack {
                                        Label {
                                            Text("Trainingsmodus").foregroundStyle(.secondary)
                                        } icon: {
                                            Image(systemName: "dumbbell.fill")
                                                .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.7))
                                        }
                                        Spacer()
                                    }

                                    VStack(spacing: 8) {
                                        ForEach(WorkoutModus.selectableCases) { modus in
                                            modusRow(modus)
                                        }
                                    }
                                    .padding(.top, 12)

                                    Text(settingsVM.preferences.workoutModus.settingsHint)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 8)
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
    
    @ViewBuilder
    private func modusRow(_ modus: WorkoutModus) -> some View {
        let isSelected = settingsVM.preferences.workoutModus == modus
        Button {
            settingsVM.setWorkoutModus(modus)
        } label: {
            HStack {
                Text(modus.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(themeManager.currentTheme.accentColor)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                isSelected ? themeManager.currentTheme.accentColor.opacity(0.12)
                           : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
    
}
