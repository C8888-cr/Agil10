//
//  LoginView.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


//
//  LoginView.swift (MAGENTA VERSION)
//  Agil9.0
//
import SwiftUI
import SwiftData
struct LoginView: View {

    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false
    @State private var showLoading = false
    

    
    var body: some View {
        ZStack {
            // Loading Screen überlagern
            if showLoading {
                LoadingView()
                    .zIndex(999)
            }
            
            NavigationStack {
                VStack(spacing: 20) {
                    
                    // ============ HEADER ============
                    VStack(spacing: 16) {
               
                            // Dein Agil Logo
                            Image("AgilLogo") // Stelle sicher, dass der Asset-Name "Agil" korrekt ist
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 180, height: 180) // Anpassbare Größe für das Logo
                        
                        
                        VStack(spacing: 8) {
                            Text("Willkommen zurück")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text("Melde dich an, um fortzufahren")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // ============ FORM ============
                    VStack(spacing: 16) {
                        // Email Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent) // Auf telekomMagenta geändert
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.accent) // Auf telekomMagenta geändert
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
                                        Color.accent.opacity( // Auf telekomMagenta geändert
                                            !ValidationHelper.isValidEmail(email) && !email.isEmpty ? 0.6 : 0.25
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        }
                        
                        // Password Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Passwort")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent) // Auf telekomMagenta geändert
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.accent) // Auf telekomMagenta geändert
                                    .font(.system(size: 14))
                                
                                SecureField("Passwort eingeben", text: $password)
                                    .textContentType(.password)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accent, lineWidth: 2) // Hier war ein Tippfehler, korrigiert
                            )
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            NavigationLink("Passwort vergessen?") {
                                ForgotPasswordView()
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.accent) // Hier war ein Tippfehler, korrigiert
                        }
                    }
                    .padding(.horizontal, 4)
                    
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
                        .background(Color.accent.opacity(0.8)) // Auf telekomMagenta geändert
                        .cornerRadius(10)
                    }
                    
                    // ============ LOGIN BUTTON ============
                    Button(action: handleLogin) {
                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Wird angemeldet...")
                                    .fontWeight(.semibold)
                            }
                        } else {
                            Text("Anmelden")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 50)
                    .foregroundColor(.white)
                    .background(Color.accent) // Von LinearGradient auf telekomMagenta geändert
                    .cornerRadius(12)
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.65)
                    // Die Shadow-Farbe habe ich auch auf telekomMagenta geändert, damit es passt.
                    .shadow(color: Color.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                    
                    Spacer()
                    
                    // ============ SIGN UP LINK ============
                    HStack(spacing: 6) {
                        Text("Noch kein Konto?")
                            .foregroundColor(.gray)
                        NavigationLink("Jetzt registrieren") {
                            SignUpView(
                            )
                        }
                        .foregroundColor(.accent) // Auf telekomMagenta geändert
                        .fontWeight(.semibold)
                    }
                    .font(.caption)
                }
                .padding(20)
                .background(
                    // Hintergrund-Gradient an Telekom Magenta angepasst
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.accent.opacity(0.1), // Leichtere Telekom Magenta-Töne
                            Color.accent.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        ValidationHelper.isValidEmail(email)
    }
    
    private func handleLogin() {
        isLoading = true
        showLoading = true
        errorMessage = nil
        
        Task {
            do {
           
                
                try await authService.login(email: email, password: password)
                
                
                if let user = authService.currentUser {
                              print("🧪 AuthService.login – User VOR Speichern:")
                              print("   email: \(user.email)")
                              print("   firstName: \(user.firstName)")
                              print("   lastName: \(user.lastName)")
                              print("   praxisId: \(String(describing: user.praxisId))")
                          }

                await MainActor.run {
                    showLoading = false
                    isLoading = false
                }
            } catch let error as AuthError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    showLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Ein unerwarteter Fehler ist aufgetreten"
                    isLoading = false
                    showLoading = false
                }
            }
        }
    }
}



