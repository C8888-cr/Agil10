//
//  ForgotPasswordView.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


//
//  ForgotPasswortView.swift (TELEKOM MAGENTA VERSION - IDENTICAL TO LOGIN)
//  Agil9.0
//
//  Created by Christiane Roth on 11.11.25.
//
import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var step: ResetStep = .enterEmail // 1. Email → 2. Code → 3. Neues PW
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    @Environment(\.dismiss) var dismiss
    
    
    let authService: AuthServiceProtocol  // ✅ Protocol!

    
    enum ResetStep {
        case enterEmail
        case enterCode
        case resetPassword
    }
    
    var body: some View {
        // ZStack für den Hintergrund, damit er sich über die gesamte View erstreckt
        ZStack {
            // Hintergrund-Gradient der LoginView
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accent.opacity(0.1), // Leichtere Telekom Magenta-Töne
                    Color.accent.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
            
      
                    // Dein Agil Logo
                    Image("AgilLogo") // Stelle sicher, dass der Asset-Name "Agil" korrekt ist
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180) 
                
                
                // ============ HEADER ============
                VStack(spacing: 12) {
                    Image(systemName: "key.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accent)
                    
                    Text("Passwort zurücksetzen")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(stepDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
                
                // ============ STEP 1: EMAIL ============
                if step == .enterEmail {
                    VStack(spacing: 12) {
                        // Email Input - Identisch zur LoginView
                        VStack(alignment: .leading, spacing: 8) { // Label für Inputfelder
                            Text("Email")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.accent)
                                    .font(.system(size: 14))
                                
                                CustomPlaceholderTextField(text: $email, placeholder: "deine@email.de")
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .accentColor(.accent)
                            }
                            .padding(14)
                            .background(Color.white) // Hintergrund ist Weiß
                            .cornerRadius(12)
                            .overlay( // Der Stroke ist identisch zur LoginView
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.accent.opacity(
                                            !ValidationHelper.isValidEmail(email) && !email.isEmpty ? 0.6 : 0.25
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        }
                        
                        Button(action: sendResetEmail) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Code senden")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity) // Button breiter machen
                            }
                        }
                        .frame(height: 50) // Höhe wie LoginButton
                        .foregroundColor(.white)
                        .background(ValidationHelper.isValidEmail(email) ? Color.accent : Color.accent.opacity(0.2))
                        .cornerRadius(12)
                        .disabled(isLoading || !ValidationHelper.isValidEmail(email))
                        .opacity(ValidationHelper.isValidEmail(email) ? 1 : 0.65) // Opacity wie LoginButton
                        .shadow(color: Color.accent.opacity(0.4), radius: 10, x: 0, y: 4) // Shadow wie LoginButton
                    }
                }
                
                // ============ STEP 2: CODE ============
                if step == .enterCode {
                    VStack(spacing: 12) {
                        Text("Wir haben einen Code an \(email) gesendet")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                        
                        // Code Input - Design wie LoginView
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reset Code") // Label hinzugefügt
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "number.square.fill") // Passendes Icon
                                    .foregroundColor(.accent)
                                    .font(.system(size: 14))
                                
                                TextField("6-stelliger Code", text: $resetCode)
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                    .accentColor(.accent)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.accent.opacity(
                                            !resetCode.isEmpty ? 0.25 : 0.6 // Statusabhängig
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        }
                        
                        Button(action: verifyCode) {
                            Text("Code bestätigen")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(!resetCode.isEmpty ? Color.accent : Color.gray)
                        .cornerRadius(12)
                        .disabled(resetCode.isEmpty)
                        .opacity(!resetCode.isEmpty ? 1 : 0.65)
                        .shadow(color: Color.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                }
                
                // ============ STEP 3: NEW PASSWORD ============
                if step == .resetPassword {
                    VStack(spacing: 12) {
                        // Neues Passwort Input - Design wie LoginView
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Neues Passwort")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.accent)
                                    .font(.system(size: 14))
                                
                                SecureField("Neues Passwort", text: $newPassword)
                                    .textContentType(.newPassword)
                                    .accentColor(.accent)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.accent.opacity(
                                            ValidationHelper.isValidPassword(newPassword) ? 0.25 : 0.6
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        }
                        
                        // Passwort wiederholen Input - Design wie LoginView
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Passwort wiederholen")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.accent)
                                    .font(.system(size: 14))
                                
                                SecureField("Passwort wiederholen", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .accentColor(.accent)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.accent.opacity(
                                            (newPassword == confirmPassword && !confirmPassword.isEmpty) ? 0.25 : 0.6
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        }
                        
                        Button(action: confirmReset) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Passwort aktualisieren")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(
                            !newPassword.isEmpty &&
                            newPassword == confirmPassword &&
                            ValidationHelper.isValidPassword(newPassword) ?
                            Color.accent : Color.gray
                        )
                        .cornerRadius(12)
                        .disabled(isLoading)
                        .opacity((!newPassword.isEmpty && newPassword == confirmPassword && ValidationHelper.isValidPassword(newPassword)) ? 1 : 0.65)
                        .shadow(color: Color.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                }
                
                // ============ MESSAGES ============
                if let error = errorMessage {
                    HStack(spacing: 10) { // Spacing angepasst
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.white) // Icon weiß wie in LoginView
                        Text(error)
                            .font(.caption)
                            .lineLimit(2) // LineLimit wie in LoginView
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accent.opacity(0.8)) // Hintergrund telekomMagenta
                    .cornerRadius(10) // CornerRadius angepasst
                }
                
                if let success = successMessage {
                    HStack(spacing: 10) { // Spacing angepasst
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white) // Icon weiß für Konsistenz
                        Text(success)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.8)) // Grüner Hintergrund für Erfolg, Opacity angepasst
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // ============ BACK BUTTON ============
                Button(action: { dismiss() }) {
                    Text("Zurück zum Login")
                        .font(.caption)
                        .foregroundColor(.accent)
                        .fontWeight(.semibold) // Wie der "Jetzt registrieren" Link in LoginView
                }
            }
            .padding(20)
        }
    }
    
    // ... (Helper-Methoden bleiben unverändert)
    private var stepDescription: String {
        switch step {
        case .enterEmail:
            return "Gib deine Email ein, um einen Reset-Code zu erhalten"
        case .enterCode:
            return "Gib den Code ein, den wir dir gesendet haben"
        case .resetPassword:
            return "Gib dein neues Passwort ein"
        }
    }
    
    private func sendResetEmail() {
        guard ValidationHelper.isValidEmail(email) else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let code = try await authService.sendPasswordResetEmail(email: email)
                await MainActor.run {
                    successMessage = "Code gesendet!"
                    step = .enterCode
                    isLoading = false
                }
            } catch let error as AuthError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Fehler beim Versenden des Codes"
                    isLoading = false
                }
            }
        }
    }
    
    private func verifyCode() {
        // Vereinfachte Verifizierung (in echtem Backend würde das geprüft)
        if !resetCode.isEmpty {
            step = .resetPassword
            successMessage = "Code bestätigt!"
        }
    }
    
    private func confirmReset() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwörter stimmen nicht überein"
            return
        }
        
        guard ValidationHelper.isValidPassword(newPassword) else {
            errorMessage = "Passwort zu kurz (min. 6 Zeichen)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.confirmPasswordReset(
                    email: email,
                    resetCode: resetCode,
                    newPassword: newPassword
                )
                
                await MainActor.run {
                    successMessage = "Passwort erfolgreich zurückgesetzt!"
                    isLoading = false
                    
                    // Nach 2 Sekunden zurück zum Login
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Fehler beim Zurücksetzen"
                    isLoading = false
                }
            }
        }
    }
}
#Preview {
    ForgotPasswordView(authService: MockAuthService())
}
struct CustomPlaceholderTextField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.gray.opacity(0.7))
                    .padding(.leading, 4) // Gleiche Padding wie TextField
            }
            TextField("", text: $text)
                .foregroundColor(.black)
        }
    }
}
