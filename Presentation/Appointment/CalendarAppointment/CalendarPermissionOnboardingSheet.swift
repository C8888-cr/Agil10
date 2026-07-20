//
//  CalendarPermissionOnboardingSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  CalendarPermissionOnboardingSheet.swift
//  Agil10.0
//
//  Erklärungs-Karte VOR der iOS-Permission-Anfrage.
//  Wird einmalig angezeigt, wenn der User noch nicht entschieden hat.
//

import SwiftUI
import AgilCore

struct CalendarPermissionOnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    let onAllow: () async -> Void   // ruft requestAccess auf
    let onSkip: () -> Void          // User will ohne Kalender weiter

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 64))
                            .foregroundStyle(themeManager.currentTheme.accentColor)
                            .padding(.top, 24)

                        Text("Deine Termine im Blick")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Wir möchten dir helfen, deine Termine zu verwalten – ohne dass du sie doppelt eintragen musst.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 8)

                    // Was passiert
                    VStack(alignment: .leading, spacing: 16) {
                        infoRow(
                            icon: "eye.fill",
                            title: "Du siehst deine Woche",
                            description: "Beim Termin-Planen werden deine bestehenden Termine angezeigt, damit du freie Zeiten siehst."
                        )
                        infoRow(
                            icon: "square.and.arrow.down.fill",
                            title: "Termine werden automatisch eingetragen",
                            description: "Neue Praxis-Termine landen direkt in deinem iPhone-Kalender. Auch auf Apple Watch und Sperrbildschirm."
                        )
                        infoRow(
                            icon: "lock.shield.fill",
                            title: "Deine Daten bleiben bei dir",
                            description: "Alles passiert lokal auf deinem iPhone. Keine Übertragung an Agil-Server oder Dritte."
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // DSGVO-Hinweis
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Du kannst die Erlaubnis jederzeit in den iOS-Einstellungen widerrufen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await onAllow()
                                dismiss()
                            }
                        } label: {
                            Text("Erlauben")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.currentTheme.accentColor)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }

                        Button {
                            onSkip()
                            dismiss()
                        } label: {
                            Text("Ohne Kalender weiter")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Kalender-Zugriff")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(themeManager.currentTheme.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
