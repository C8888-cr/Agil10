//
//  SignUpView.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


//
//  SignUpView.swift
//  Agil9.0
//
//  Created by Christiane Roth on 11.11.25.
//
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
    @State private var selectedPraxisId: Int? = nil
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService




       
    var body: some View {
        // ZStack für den Hintergrund, damit er sich über die gesamte View erstreckt
        ZStack {
            // Hintergrund-Gradient der LoginView
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accent.opacity(0.1),
                    Color.accent.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing

            )
            .ignoresSafeArea()
            
            // ScrollView, um alle Inhalte scrollbar zu machen
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) { // spacing: 0 hier ist okay, da ScrollView + inneres VStack später eigenen spacing haben
                    
                    // ============ HEADER ============
                    VStack(spacing: 12) {
                    
            
                            // Dein Agil Logo
                            Image("AgilLogo") // Stelle sicher, dass der Asset-Name "Agil" korrekt ist
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 180, height: 180) // Anpassbare Größe für das Logo
                        
                        Text("Neues Konto erstellen")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .padding(.bottom, 20)
                
                    // ============ FORM ============
                    VStack(spacing: 12) { // Dieser VStack hat einen spacing von 12 zwischen den Formfeldern
                        // First Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vorname")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.accent)
                                    .font(.system(size: 14))
                                
                                TextField("Vorname", text: $firstName)
                                    .accentColor(.accent)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accent.opacity(0.25), lineWidth: 2)
                            )
                        }
                        
                        // Last Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nachname")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.accent)
                                    .font(.system(size: 14))
                                
                                TextField("Nachname", text: $lastName)
                                    .accentColor(.accent)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accent.opacity(0.25), lineWidth: 2)
                            )
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
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
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Passwort")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.accent)
                                    .font(.system(size: 14))
                                
                                SecureField("Min. 6 Zeichen", text: $password)
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
                                            !ValidationHelper.isValidPassword(password) && !password.isEmpty ? 0.6 : 0.25
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        }
                        
                        // Confirm Password
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
                                            password != confirmPassword && !confirmPassword.isEmpty ? 0.6 : 0.25
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        }
                        
                        // Toggle: Sind Sie Therapeut?
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kontotyp")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                            
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
                                        .stroke(Color.accent.opacity(0.25), lineWidth: 2)
                                )
                            }
                        }
                 
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ihre Praxis")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                                                
                            // Hier ist die Änderung: Picker in ein HStack packen
                            HStack {
                                Spacer()// <-- NEU: HStack um den Picker
                                Picker("Praxis auswählen", selection: $selectedPraxisId) {
                                    Text("Bitte wählen Sie Ihre Praxis")
                                        .tag(nil as Int?)
                                    ForEach(PraxisDataManager.shared.praxen) { praxis in
                                        Text(praxis.name)
                                            .tag(praxis.id as Int?)
                                    }
                                }
                                .pickerStyle(.menu) // Oder .wheel, .inline für andere Darstellungen
                                .accentColor(.accent)
                                // Das Padding vom Picker selbst entfernen, damit es das HStack bekommt
                                // .padding(14) // <-- DIESE ZEILE ENTFERNEN ODER AUSKOMMENTIEREN
                                
                                Spacer() // <-- Optional: Sorgt dafür, dass der Picker-Inhalt links bleibt und der Hintergrund sich ausdehnt
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.accent.opacity(
                                            selectedPraxisId == nil ? 0.6 : 0.25
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        }
                                        } // Ende Formular VStack
                    
                    
                    
                    
                    // Ende Formular VStack
                    .padding(.bottom, 20) // Abstand zum nächsten Element
                    
                    // ============ ERROR MESSAGE ============
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
                        .padding(.bottom, 10) // Abstand zum Button
                    }
                    
                    // ============ SIGN UP BUTTON ============
                    Button(action: handleSignUp) {
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
                        isFormValid ? Color.accent : Color.accent.opacity(0.2)
                    )
                    .cornerRadius(12)
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.65)
                    .shadow(color: Color.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                    .padding(.bottom, 20) // Abstand zum "Zurück zum Login" Button
                    
                    // ============ BACK BUTTON ============
                    Button(action: { dismiss() }) {
                        Text("Zurück zum Login")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.accent)
                    }
                } // Ende Haupt-VStack in ScrollView
                .padding(20) // Gesamtes ScrollView-Inhalt hat 20 Punkte Padding
            } // Ende ScrollView
        } // Ende ZStack
    }
    
    // ============ VALIDATION ============
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        ValidationHelper.isValidEmail(email) &&
        ValidationHelper.isValidPassword(password) &&
        password == confirmPassword
    }
    
    // ============ SIGN UP HANDLER ============
    private func handleSignUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwörter stimmen nicht überein"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
               do {
                   // ✅ User registrieren (Token wird intern gespeichert)
                   try await authService.signUp(
                       email: email,
                       password: password,
                       firstName: firstName,
                       lastName: lastName,
                       isTherapist: isTherapist,
                       praxisId: selectedPraxisId
                   )
                   
                   await MainActor.run {
                       isLoading = false
                       print("✅ Registrierung erfolgreich für: \(email)")
                       print("🔑 Token gespeichert: \(authService.sessionToken ?? "N/A")")
                       dismiss()  // ✅ Zurück - AppRouter erkennt currentUser
                   }
               } catch {
                   await MainActor.run {
                       errorMessage = "Registrierung fehlgeschlagen: \(error.localizedDescription)"
                       isLoading = false
                   }
               }
           }
       }
}
#Preview {
    SignUpView(
    )
}
/*
import SwiftUI

struct SignUpView: View {
    var body: some View {
        Text("TEMP - SignUpView")
    }
}
*/
