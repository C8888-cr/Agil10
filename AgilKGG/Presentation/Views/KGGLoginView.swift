//
//  KGGLoginView.swift
//  AgilKGG
//
//  Login: Praxis auswählen (Wheel-Picker) + Admin-Passwort
//  Reset-Flow klappt inline auf.
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
                    praxisPickerSection

                    if viewModel.showResetFlow {
                        resetSection
                    } else {
                        passwordSection
                        loginButton
                        forgotPasswordButton
                    }
                }
                .padding(20)
            }
        }
        .tint(accent)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            if let image = UIImage(named: "AgilLogo") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
            }

            Text("Therapeuten-App")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    // MARK: - Praxis-Auswahl (Wheel-Picker)

    private var praxisPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Praxis")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accent)

            Picker("Praxis", selection: Binding(
                get: { viewModel.selectedPraxisId ?? viewModel.allPraxen.first?.id },
                set: { viewModel.selectedPraxisId = $0 }
            )) {
                ForEach(viewModel.allPraxen) { praxis in
                    Text(praxis.name).tag(Optional(praxis.id))
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Passwort + Error

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

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }
        }
    }

    // MARK: - Login Button

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
                resetStep1
            } else {
                resetStep2
            }

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var resetStep1: some View {
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
    }

    private var resetStep2: some View {
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

    // MARK: - Error Banner

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
        .background(Color.red.opacity(0.8))
        .cornerRadius(10)
    }
}

// MARK: - RevealSecureField

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
