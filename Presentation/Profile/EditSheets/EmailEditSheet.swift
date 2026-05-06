//
//  EmailEditSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 18.02.26.
//


import SwiftUI
import SwiftData


struct EmailEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    
    @State private var newEmail: String = ""
    @State private var verificationCode: String = ""
    @State private var showVerification: Bool = false
    @State private var emailError: String = ""
    @State private var codeError: String = ""
    @State private var isLoading: Bool = false
    @State private var step: EmailEditStep = .enterEmail
    
    let user: User
    
    enum EmailEditStep {
        case enterEmail
        case verification
    }
    
    init(user: User) {
        self.user = user
        _newEmail = State(initialValue: user.email)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // ✅ SCHRITT 1: EMAIL EINGEBEN
                    if step == .enterEmail {
                        emailInputView
                    }
                    
                    // ✅ SCHRITT 2: VERIFIZIERUNG
                    if step == .verification {
                        verificationView
                    }
                    
                    Spacer()
                    
                    // ✅ BUTTONS
                    VStack(spacing: 12) {
                        if step == .enterEmail {
                            Button {
                                Task {
                                    await sendVerificationCode()
                                }
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Verifizierungscode senden")
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isEmailValid ? themeManager.currentTheme.accentColor : Color.gray.opacity(0.5))
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                            .disabled(!isEmailValid || isLoading)
                        } else {
                            Button {
                                Task {
                                    await confirmEmail()
                                }
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Email aktualisieren")
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isCodeValid ? themeManager.currentTheme.accentColor : Color.gray.opacity(0.5))
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                            .disabled(!isCodeValid || isLoading)
                        }
                        
                        Button {
                            if step == .verification {
                                step = .enterEmail
                                verificationCode = ""
                                codeError = ""
                            } else {
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text(step == .verification ? "Zurück" : "Abbrechen")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("Email ändern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // ✅ EMAIL INPUT VIEW
    private var emailInputView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Neue Email-Adresse")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                TextField("neue.email@example.com", text: $newEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onChange(of: newEmail) { _, newValue in
                        if !newValue.isEmpty {
                            emailError = ""
                        }
                    }
                
                if !emailError.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(emailError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal)
                }
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Aktuelle Email: \(user.email)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // ✅ VERIFICATION VIEW
    private var verificationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verifizierungscode")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Text("Wir haben einen Verifizierungscode an \(newEmail) gesendet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                TextField("000000", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .tracking(2)
                    .font(.system(.title3, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onChange(of: verificationCode) { _, newValue in
                        // Nur Zahlen
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            verificationCode = filtered
                        }
                        // Auto clear error
                        if !newValue.isEmpty {
                            codeError = ""
                        }
                    }
                
                if !codeError.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(codeError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal)
                }
                
                // ✅ RESEND BUTTON
                Button {
                    Task {
                        await sendVerificationCode()
                    }
                } label: {
                    Text("Code erneut senden")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.accentColor)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // ✅ VALIDATION
    private var isEmailValid: Bool {
        ValidationHelper.isValidEmail(newEmail) &&
        newEmail.lowercased() != user.email.lowercased()
    }
    
    private var isCodeValid: Bool {
        !verificationCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        verificationCode.count >= 5
    }
    
    // ✅ SEND VERIFICATION CODE
    private func sendVerificationCode() async {
        isLoading = true
        emailError = ""
        
        // Validierung
        guard ValidationHelper.isValidEmail(newEmail) else {
            emailError = "Ungültige Email-Adresse"
            isLoading = false
            return
        }
        
        guard newEmail.lowercased() != user.email.lowercased() else {
            emailError = "Das ist deine aktuelle Email"
            isLoading = false
            return
        }
        
        // Simuliere API-Call
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // TODO: Mit Backend kommunizieren
        // await authService.sendEmailVerificationCode(to: newEmail)
        
        print("✅ Verifizierungscode an \(newEmail) gesendet")
        step = .verification
        isLoading = false
    }
    
    // ✅ CONFIRM EMAIL
    private func confirmEmail() async {
        isLoading = true
        codeError = ""
        
        guard !verificationCode.isEmpty else {
            codeError = "Bitte gib den Code ein"
            isLoading = false
            return
        }
        
        // Simuliere API-Call
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        do {
            // TODO: Mit Backend kommunizieren
            // let isValid = await authService.verifyEmailCode(code: verificationCode)
            // if !isValid { throw ... }
            
            // ✅ Verifizierungscode validieren (für jetzt: dummy)
            let isCodeValid = verificationCode == "123456"
            
            if !isCodeValid {
                codeError = "Ungültiger Code"
                isLoading = false
                return
            }
            
            // ✅ Email in SwiftData aktualisieren
            user.email = newEmail.lowercased()
            
            try modelContext.save()
            
            // ✅ AuthService aktualisieren
            //weg weil angeblich unnötig. falls doch: sessionManager
         //   authService.currentUser = user
            
            print("✅ Email aktualisiert auf: \(newEmail)")
            
            isLoading = false
            dismiss()
            
        } catch {
            codeError = "Fehler beim Aktualisieren"
            isLoading = false
            print("❌ Fehler: \(error)")
        }
    }
}
#Preview {
    let container = try! ModelContainer(
        for: User.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let mockUser = User(
        firstName: "Max",
        lastName: "Mustermann",
        email: "old.email@example.com",
        passwordHash: "hash",
        role: .patient,
        praxisId: nil
    )
    
    EmailEditSheet(user: mockUser)
        .environment(\.modelContext, container.mainContext)
}
