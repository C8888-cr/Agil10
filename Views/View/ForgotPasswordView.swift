import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var emailSent = false  // ← statt step-Enum
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accent.opacity(0.1),
                    Color.accent.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                Image("AgilLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: emailSent ? "checkmark.circle.fill" : "key.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(emailSent ? .green : .accent)
                    
                    Text("Passwort zurücksetzen")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(emailSent
                         ? "Wir haben dir eine Email an \(email) gesendet. Klicke auf den Link in der Email um dein Passwort zurückzusetzen."
                         : "Gib deine Email ein — wir schicken dir einen Link zum Zurücksetzen.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 20)
                
                // MARK: - Email eingeben (nur wenn noch nicht gesendet)
                if !emailSent {
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.accent)
                                    .font(.system(size: 14))
                                
                                CustomPlaceholderTextField(
                                    text: $email,
                                    placeholder: "deine@email.de"
                                )
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .accentColor(.accent)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
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
                                ProgressView().tint(.white)
                            } else {
                                Text("Link senden")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(ValidationHelper.isValidEmail(email) ? Color.accent : Color.accent.opacity(0.2))
                        .cornerRadius(12)
                        .disabled(isLoading || !ValidationHelper.isValidEmail(email))
                        .opacity(ValidationHelper.isValidEmail(email) ? 1 : 0.65)
                        .shadow(color: Color.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                }
                
                // MARK: - Fehler
                if let error = errorMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.white)
                        Text(error)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accent.opacity(0.8))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // MARK: - Zurück Button
                Button(action: { dismiss() }) {
                    Text(emailSent ? "Zurück zum Login" : "Abbrechen")
                        .font(.caption)
                        .foregroundColor(.accent)
                        .fontWeight(.semibold)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Aktion
    private func sendResetEmail() {
        guard ValidationHelper.isValidEmail(email) else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Firebase schickt den Link selbst — wir müssen nichts weiter tun
                _ = try await authService.sendPasswordResetEmail(email: email)
                await MainActor.run {
                    emailSent = true  // ← Screen wechselt zu Bestätigung
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Email konnte nicht gesendet werden. Prüfe die Adresse."
                    isLoading = false
                }
            }
        }
    }
}


struct CustomPlaceholderTextField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.gray.opacity(0.7))
                    .padding(.leading, 4)
            }
            TextField("", text: $text)
                .foregroundColor(.black)
        }
    }
}


#Preview {
    ForgotPasswordView()
        .environmentObject(AuthService(authServiceProtocol: MockAuthService()))
}
