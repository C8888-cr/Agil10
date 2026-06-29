//
//  KGGLoginView.swift
//  AgilKGG
//
//  Login: Praxis auswählen (nur Name) + Admin-Passwort
//  Reset-Flow klappt inline auf. Optik an LoginView/LibraryView angelehnt.
//

import SwiftUI
import AgilCore
import Combine

struct KGGLoginView: View {
    @EnvironmentObject var viewModel: KGGAuthViewModel
    @EnvironmentObject var themeManager: ThemeManager

    private var accent: Color { themeManager.currentTheme.accentColor }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
               
                VStack(spacing: 24) {
                    headerView

                    praxisSelectionSection

                    if viewModel.showResetFlow {
                        resetSection
                    } else {
                        passwordSection
                        loginButton
                        forgotPasswordButton
                    }

                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding(20)
            }
        }
        .tint(accent)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 16) {
            if let image = UIImage(named: "AgilLogo") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
            } else {
                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(accent)
            }

            VStack(spacing: 6) {
                Text("agil KGG")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Therapeuten-App")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Praxis-Auswahl (nur Name)

    private var praxisSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Praxis")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accent)

            VStack(spacing: 8) {
                ForEach(viewModel.allPraxen) { praxis in
                    praxisRow(praxis)
                }
            }
        }
    }

    private func praxisRow(_ praxis: KGGPraxis) -> some View {
        let isSelected = viewModel.selectedPraxisId == praxis.id
        return Button {
            viewModel.selectedPraxisId = praxis.id
            viewModel.errorMessage = nil
        } label: {
            HStack {
                Text(praxis.name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(accent)
                }
            }
            .padding(14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accent : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Passwort

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Admin-Passwort")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accent)

            RevealSecureField(
                placeholder: "Passwort eingeben",
                text: $viewModel.passwordInput,
                accent: accent
            )
        }
    }

    private var loginButton: some View {
        let enabled = viewModel.selectedPraxisId != nil && !viewModel.passwordInput.isEmpty
        return Button {
            viewModel.login()
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Anmelden").fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .foregroundStyle(.white)
        .background(enabled ? accent : Color.gray)
        .cornerRadius(12)
        .disabled(!enabled || viewModel.isLoading)
    }

    private var forgotPasswordButton: some View {
        Button {
            viewModel.startReset()
        } label: {
            Text("Passwort vergessen?")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Reset-Flow (inline)

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Passwort zurücksetzen")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    viewModel.cancelReset()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.resetTempPassword == nil {
                // Schritt 1: Reset-Code
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reset-Code")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(accent)

                    TextField("z.B. ResetPraxis1", text: $viewModel.resetCode)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        viewModel.validateResetCode()
                    } label: {
                        Text("Code prüfen")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .foregroundStyle(.white)
                    .background(viewModel.resetCode.isEmpty ? Color.gray : accent)
                    .cornerRadius(10)
                    .disabled(viewModel.resetCode.isEmpty || viewModel.isLoading)
                }
            } else {
                // Schritt 2: Neues Passwort
                VStack(alignment: .leading, spacing: 12) {
                    Text("Code akzeptiert. Bitte neues Passwort vergeben.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    RevealSecureField(
                        placeholder: "Neues Passwort",
                        text: $viewModel.newPasswordInput,
                        accent: accent
                    )
                    RevealSecureField(
                        placeholder: "Passwort bestätigen",
                        text: $viewModel.confirmPasswordInput,
                        accent: accent
                    )

                    Button {
                        viewModel.setNewPassword()
                    } label: {
                        Text("Passwort speichern")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .foregroundStyle(.white)
                    .background(accent)
                    .cornerRadius(10)
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Error

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.caption)
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(12)
        .background(accent.opacity(0.85))
        .cornerRadius(10)
    }
}

// MARK: - Wiederverwendbares Passwortfeld mit Auge-Toggle

struct RevealSecureField: View {
    let placeholder: String
    @Binding var text: String
    let accent: Color

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundStyle(accent)
                .font(.system(size: 14))

            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accent.opacity(0.25), lineWidth: 2)
        )
    }
}

#Preview {
    KGGLoginView()
        .environmentObject(KGGAuthViewModel())
        .environmentObject(ThemeManager())
}
