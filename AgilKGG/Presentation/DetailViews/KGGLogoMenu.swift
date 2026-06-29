//
//  KGGLogoMenu.swift
//  AgilKGG
//
//  Wiederverwendbares agil-Logo oben rechts mit Logout-Menü.
//  In jede View per .toolbar einsetzbar → Single Source of Truth.
//

import SwiftUI
import AgilCore

struct KGGLogoMenu: View {
    @EnvironmentObject var authViewModel: KGGAuthViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showLogoutConfirm = false

    private var accent: Color { themeManager.currentTheme.accentColor }

    var body: some View {
        Menu {
            if let praxisName = authViewModel.currentCredentials?.praxisName {
                Section(praxisName) {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            } else {
                Button(role: .destructive) {
                    showLogoutConfirm = true
                } label: {
                    Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            logoLabel
        }
        .confirmationDialog(
            "Wirklich abmelden?",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Abmelden", role: .destructive) {
                authViewModel.logout()
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Die Sitzung wird sicher beendet.")
        }
    }

    @ViewBuilder
    private var logoLabel: some View {
        if let image = UIImage(named: "AgilLogo") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Text("agil")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
        }
    }
}

// MARK: - Bequemer Modifier für jede View

extension View {
    /// Hängt das agil-Logo-Menü mit Logout oben rechts an.
    func kggLogoToolbar() -> some View {
        self.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                KGGLogoMenu()
            }
        }
    }
}
