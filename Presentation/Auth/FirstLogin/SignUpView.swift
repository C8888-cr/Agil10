import SwiftUI
import SwiftData



struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isTherapist = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPraxisId: UUID? = nil
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accent.opacity(0.00),
                    Color.accent.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HeaderSection()
                        .padding(.bottom, 20)
                    
                    FormSection(
                        email: $email,
                        password: $password,
                        confirmPassword: $confirmPassword,
                        firstName: $firstName,
                        lastName: $lastName,
                        selectedPraxisId: $selectedPraxisId
                    )
                    .padding(.bottom, 20)
                    
                    if let error = errorMessage {
                        ErrorMessageSection(error: error)
                            .padding(.bottom, 10)
                    }
                    
                    SignUpButtonSection(
                        isLoading: isLoading,
                        isFormValid: isFormValid,
                        action: handleSignUp
                    )
                    .padding(.bottom, 20)
                    
                    BackButtonSection(dismiss: dismiss)
                }
                .padding(20)
            }
        }
        .tint(Color("AccentColor"))
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        ValidationHelper.isValidEmail(email) &&
        ValidationHelper.isValidPassword(password) &&
        password == confirmPassword &&
        selectedPraxisId != nil
    }
    
    private func handleSignUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwörter stimmen nicht überein"
            return
        }
        isLoading = true
        errorMessage = nil
        
        Task {
            let request = SignUpRequest(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                praxisId: selectedPraxisId
            )
            await authViewModel.signUp(request: request)
            await MainActor.run {
                if let error = authViewModel.errorMessage {
                    errorMessage = error
                    authViewModel.errorMessage = nil
                } else {
                    print("✅ Registrierung erfolgreich für: \(email)")
                    dismiss()
                }
                isLoading = false
            }
        }
    }
}
// MARK: - Header Section
struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("AgilLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
            
            Text("Neues Konto erstellen")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
        }
    }
}
// MARK: - Form Section
struct FormSection: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var firstName: String
    @Binding var lastName: String

    @Binding var selectedPraxisId: UUID?
    
    var body: some View {
        VStack(spacing: 12) {
            FirstNameField(firstName: $firstName)
            LastNameField(lastName: $lastName)
            EmailField(email: $email)
            PasswordField(password: $password)
            ConfirmPasswordField(password: $password, confirmPassword: $confirmPassword)
        
            PraxisPickerField(selectedPraxisId: $selectedPraxisId)
        }
    }
}
// MARK: - Individual Form Fields
struct FirstNameField: View {
    @Binding var firstName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vorname")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AccentColor"))
            
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundColor(Color("AccentColor"))
                    .font(.system(size: 14))
                
                TextField("Vorname", text: $firstName)
                    .tint(Color("AccentColor"))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("AccentColor").opacity(0.25), lineWidth: 2)
            )
        }
    }
}
struct LastNameField: View {
    @Binding var lastName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nachname")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AccentColor"))
            
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundColor(Color("AccentColor"))
                    .font(.system(size: 14))
                
                TextField("Nachname", text: $lastName)
                    .tint(Color("AccentColor"))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("AccentColor").opacity(0.25), lineWidth: 2)
            )
        }
    }
}
struct EmailField: View {
    @Binding var email: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AccentColor"))
            
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(Color("AccentColor"))
                    .font(.system(size: 14))
                
                CustomPlaceholderTextField(text: $email, placeholder: "deine@email.de")
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .tint(Color("AccentColor"))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color("AccentColor").opacity(
                            !ValidationHelper.isValidEmail(email) && !email.isEmpty ? 0.6 : 0.25
                        ),
                        lineWidth: 2
                    )
            )
        }
    }
}
struct PasswordField: View {
    @Binding var password: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Passwort")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AccentColor"))
            
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(Color("AccentColor"))
                    .font(.system(size: 14))
                
                SecureField("Passwort", text: $password)
                                  .textContentType(.newPassword)
                                  .tint(Color("AccentColor"))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color("AccentColor").opacity(
                            !ValidationHelper.isValidPassword(password) && !password.isEmpty ? 0.6 : 0.25
                        ),
                        lineWidth: 2
                    )
            )
            Text("Mind. 8 Zeichen mit Groß-/Kleinbuchstabe, Zahl und Sonderzeichen")
                          .font(.caption2)
                          .foregroundColor(.secondary)
                          .padding(.horizontal, 4)
        }
    }
}
struct ConfirmPasswordField: View {
    @Binding var password: String
    @Binding var confirmPassword: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Passwort wiederholen")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AccentColor"))
            
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(Color("AccentColor"))
                    .font(.system(size: 14))
                
                SecureField("Passwort wiederholen", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .tint(Color("AccentColor"))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color("AccentColor").opacity(
                            password != confirmPassword && !confirmPassword.isEmpty ? 0.6 : 0.25
                        ),
                        lineWidth: 2
                    )
            )
        }
    }
}
struct TherapistToggleField: View {
    @Binding var isTherapist: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kontotyp")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
            
            HStack {
                Toggle(isOn: $isTherapist) {
                    Text("Ich bin Therapeut/in")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .tint(.accent)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("AccentColor").opacity(0.25), lineWidth: 2)
                )
            }
        }
    }
}
struct PraxisPickerField: View {
    @Binding var selectedPraxisId: UUID?
    
    private var selectedPraxisName: String {
        guard let id = selectedPraxisId,
              let praxis = PraxisDataManager.shared.praxen.first(where: { $0.id == id })
        else {
            return "Bitte wählen Sie Ihre Praxis"
        }
        return praxis.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ihre Praxis")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AccentColor"))
            
            Menu {
                Button("Bitte wählen Sie Ihre Praxis") {
                    selectedPraxisId = nil
                }
                ForEach(PraxisDataManager.shared.praxen) { praxis in
                    Button(praxis.name) {
                        selectedPraxisId = praxis.id
                    }
                }
            } label: {
                HStack {
                    Text(selectedPraxisName)
                        .foregroundColor(Color("AccentColor"))   // ← jetzt garantiert pink
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(Color("AccentColor"))
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color("AccentColor").opacity(
                                selectedPraxisId == nil ? 0.6 : 0.25
                            ),
                            lineWidth: 2
                        )
                )
            }
        }
    }
}
// MARK: - Error Message Section
struct ErrorMessageSection: View {
    let error: String
    
    var body: some View {
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
        .background(Color("AccentColor").opacity(0.8))
        .cornerRadius(10)
    }
}
// MARK: - Sign Up Button Section
struct SignUpButtonSection: View {
    let isLoading: Bool
    let isFormValid: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Registrieren")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 50)
        .foregroundColor(.white)
        .background(
            isFormValid ? Color("AccentColor") : Color("AccentColor").opacity(0.2)
        )
        .cornerRadius(12)
        .disabled(isLoading || !isFormValid)
        .opacity(isFormValid ? 1 : 0.65)
        .shadow(color: Color("AccentColor").opacity(0.4), radius: 10, x: 0, y: 4)
    }
}
// MARK: - Back Button Section
struct BackButtonSection: View {
    let dismiss: DismissAction
    
    var body: some View {
        Button(action: { dismiss() }) {
            Text("Zurück zum Login")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AccentColor"))
        }
    }
}
#Preview {
    SignUpView()
}
