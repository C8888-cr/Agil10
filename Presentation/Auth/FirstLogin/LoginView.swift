//
//  LoginView.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//
/*

import SwiftUI
import SwiftData
struct LoginView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    
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
                        
                        // Password Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Passwort")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("AccentColor"))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Color("AccentColor"))
                                    .font(.system(size: 14))
                                
                                SecureField("Passwort eingeben", text: $password)
                                    .textContentType(.password)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("AccentColor"), lineWidth: 2)
                            )
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            NavigationLink("Passwort vergessen?") {
                                ForgotPasswordView { email in
                                        await authViewModel.resetPassword(email: email)
                                   }
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AccentColor"))
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
                        .background(Color("AccentColor").opacity(0.8))
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
                    .background(Color("AccentColor"))
                    .cornerRadius(12)
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.65)
                  
                    .shadow(color: Color("AccentColor").opacity(0.4), radius: 10, x: 0, y: 4)
                    
                    Spacer()
                    
                    // ============ SIGN UP LINK ============
                    HStack(spacing: 6) {
                        Text("Noch kein Konto?")
                            .foregroundColor(.gray)
                        NavigationLink("Jetzt registrieren") {
                            SignUpView(
                            )
                        }
                        .foregroundColor(Color("AccentColor")) 
                        .fontWeight(.semibold)
                    }
                    .font(.caption)
                }
                .padding(20)
                .background(Color(.systemGroupedBackground))
            }
            
        }
        .tint(Color("AccentColor"))
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
            print("🔐 Login gestartet für: \(email)")
            await authViewModel.login(email: email, password: password)
            await MainActor.run {
                print("🔐 Login fertig – errorMessage: \(authViewModel.errorMessage ?? "nil")")
                print("🔐 session.isAuthenticated: \(authViewModel.session.isAuthenticated)")
                print("🔐 session.currentUser: \(authViewModel.session.currentUser?.email ?? "nil")")
                if let error = authViewModel.errorMessage {
                    errorMessage = error
                    authViewModel.errorMessage = nil
                }
                isLoading = false
                showLoading = false
            }
        }
    }
}

*/
import SwiftUI
import SwiftData

struct LoginView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false
    @State private var showLoading = false

    var body: some View {
        ZStack {
            if showLoading {
                LoadingView()
                    .zIndex(999)
            }
            
            NavigationStack {
                VStack(spacing: 20) {
                    
                    // ============ HEADER ============
                    VStack(spacing: 16) {
                        Image("AgilLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)
                        
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
                    
                    // ============ FACE ID BUTTON (NEU) ============
                    if authViewModel.canUseBiometricLogin {
                        Button(action: handleBiometricLogin) {
                            HStack(spacing: 10) {
                                Image(systemName: "faceid")
                                    .font(.title3)
                                Text("Mit Face ID anmelden")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(.white)
                            .background(Color("AccentColor"))
                            .cornerRadius(12)
                            .shadow(color: Color("AccentColor").opacity(0.4), radius: 10, x: 0, y: 4)
                        }
                        
                        // Trennlinie "oder"
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("oder")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // ============ FORM ============
                    VStack(spacing: 16) {
                        // Email Input
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
                        
                        // Password Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Passwort")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("AccentColor"))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Color("AccentColor"))
                                    .font(.system(size: 14))
                                
                                SecureField("Passwort eingeben", text: $password)
                                    .textContentType(.password)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("AccentColor"), lineWidth: 2)
                            )
                        }
             
                        // Forgot Password
                   /*     HStack {
                            Spacer()
                            NavigationLink("Passwort vergessen?") {
                                ForgotPasswordView { email in
                                    await authViewModel.resetPassword(email: email)
                                }
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AccentColor"))
                        }
                    */
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
                        .background(Color("AccentColor").opacity(0.8))
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
                    .background(Color("AccentColor"))
                    .cornerRadius(12)
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1 : 0.65)
                    .shadow(color: Color("AccentColor").opacity(0.4), radius: 10, x: 0, y: 4)
                    
                    Spacer()
                    
                    // ============ SIGN UP LINK ============
                    HStack(spacing: 6) {
                        Text("Noch kein Konto?")
                            .foregroundColor(.gray)
                        NavigationLink("Jetzt registrieren") {
                            SignUpView()
                        }
                        .foregroundColor(Color("AccentColor"))
                        .fontWeight(.semibold)
                    }
                    .font(.caption)
                }
                .padding(20)
                .background(Color(.systemGroupedBackground))
            }
        }
        .tint(Color("AccentColor"))
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
            print("🔐 Login gestartet für: \(email)")
            await authViewModel.login(email: email, password: password)
            await MainActor.run {
                if let error = authViewModel.errorMessage {
                    errorMessage = error
                    authViewModel.errorMessage = nil
                }
                isLoading = false
                showLoading = false
            }
        }
    }
    
    // NEU: Face ID Login Handler
    private func handleBiometricLogin() {
        showLoading = true
        errorMessage = nil
        
        Task {
            await authViewModel.loginWithBiometric()
            await MainActor.run {
                if let error = authViewModel.errorMessage {
                    errorMessage = error
                    authViewModel.errorMessage = nil
                }
                showLoading = false
            }
        }
    }
}
