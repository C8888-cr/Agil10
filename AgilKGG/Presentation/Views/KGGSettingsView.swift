//
//  KGGSettingsView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.07.26.
//


//
//  KGGSettingsView.swift
//  AgilKGG
//
//  Einstellungen: Praxis-Info, Passwort ändern, Danger Zone (Praxisdaten löschen)
//

import SwiftUI
import SwiftData
import AgilCore

struct KGGSettingsView: View {
    @EnvironmentObject var authViewModel: KGGAuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    let credentials: KGGLoginCredentials

    @State private var showChangePasswordSheet = false
    @State private var showDeleteConfirmSheet = false

    private var accent: Color { themeManager.currentTheme.accentColor }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    praxisInfoSection
                    securitySection
                    aboutSection
                    logoutButton
                    dangerZoneSection
                }
                .padding(16)
            }
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChangePasswordSheet) {
            KGGChangePasswordSheet()
                .environmentObject(authViewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showDeleteConfirmSheet) {
            KGGDeletePraxisDataSheet(modelContext: modelContext)
                .environmentObject(authViewModel)
                .environmentObject(themeManager)
        }
    }

    // MARK: - Sections

    private var praxisInfoSection: some View {
        section(title: "Praxis-Informationen") {
            VStack(alignment: .leading, spacing: 12) {
                infoRow(label: "Praxis", value: credentials.praxisName)
                infoRow(label: "Angemeldet seit", value: formatDate(credentials.loginTime))
                if let therapist = credentials.therapistName {
                    infoRow(label: "Therapeut", value: therapist)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }

    private var securitySection: some View {
        section(title: "Sicherheit") {
            Button {
                showChangePasswordSheet = true
            } label: {
                HStack {
                    Label("Admin-Passwort ändern", systemImage: "key.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.primary)
                .padding(14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutSection: some View {
        section(title: "Über") {
            VStack(alignment: .leading, spacing: 12) {
                infoRow(label: "App", value: "Agil KGG")
                infoRow(label: "Version", value: "1.0.0")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            authViewModel.logout()
        } label: {
            Text("Abmelden")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var dangerZoneSection: some View {
        section(title: "Danger Zone", titleColor: .red) {
            Button {
                showDeleteConfirmSheet = true
            } label: {
                HStack {
                    Label("Alle Praxisdaten löschen", systemImage: "trash.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.red)
                .padding(14)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Text("Löscht unwiderruflich alle Patienten, Übungen, Historie und Videos dieser Praxis.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Bausteine

    @ViewBuilder
    private func section(title: String, titleColor: Color? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(titleColor ?? accent)
            content()
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

// MARK: - Passwort ändern (Sheet)

struct KGGChangePasswordSheet: View {
    @EnvironmentObject var authViewModel: KGGAuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    private var accent: Color { themeManager.currentTheme.accentColor }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        RevealSecureField(placeholder: "Aktuelles Passwort", text: $currentPassword, accent: accent)
                        RevealSecureField(placeholder: "Neues Passwort (min. 8 Zeichen)", text: $newPassword, accent: accent)
                        RevealSecureField(placeholder: "Neues Passwort bestätigen", text: $confirmPassword, accent: accent)

                        Button {
                            let success = authViewModel.changePassword(
                                current: currentPassword,
                                new: newPassword,
                                confirm: confirmPassword
                            )
                            if success { dismiss() }
                        } label: {
                            Text("Passwort speichern")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .foregroundStyle(.white)
                        .background(formValid ? accent : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(!formValid)

                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Passwort ändern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        authViewModel.errorMessage = nil
                        dismiss()
                    }
                }
            }
        }
    }

    private var formValid: Bool {
        !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty
    }
}

// MARK: - Praxisdaten löschen (Sheet, zweistufig abgesichert)

struct KGGDeletePraxisDataSheet: View {
    @EnvironmentObject var authViewModel: KGGAuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let modelContext: ModelContext

    @State private var passwordInput = ""
    @State private var showFinalAlert = false

    private var accent: Color { themeManager.currentTheme.accentColor }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Diese Aktion ist unwiderruflich", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)

                        Text("Alle Patienten, Übungen, Historie, Warmups, Bibliotheks-Übungen und verschlüsselten Videos dieser Praxis werden dauerhaft gelöscht. Zur Bestätigung bitte das Admin-Passwort eingeben.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        RevealSecureField(placeholder: "Admin-Passwort", text: $passwordInput, accent: accent)

                        Button {
                            showFinalAlert = true
                        } label: {
                            Text("Alle Praxisdaten löschen")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .foregroundStyle(.white)
                        .background(passwordInput.isEmpty ? Color.gray : Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(passwordInput.isEmpty)

                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Praxisdaten löschen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        authViewModel.errorMessage = nil
                        dismiss()
                    }
                }
            }
            .alert("Wirklich alles löschen?", isPresented: $showFinalAlert) {
                Button("Endgültig löschen", role: .destructive) {
                    let success = authViewModel.deletePraxisData(
                        password: passwordInput,
                        modelContext: modelContext
                    )
                    if success { dismiss() }  // Logout passiert im ViewModel
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
    }
}