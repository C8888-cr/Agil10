import SwiftUI
import SwiftData
struct RoleEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedRole: UserRole
    @State private var therapistCode: String = ""
    @State private var showCodeInput: Bool = false
    @State private var codeError: String = ""
    @State private var isLoading: Bool = false
    
    let user: User
    
    init(user: User) {
        self.user = user
        _selectedRole = State(initialValue: user.role)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // ✅ ROLLE AUSWÄHLEN
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Berechtigungen")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            // Patient Option
                            RoleOptionButton(
                                title: "Patient",
                                description: "Deine Termine verwalten",
                                icon: "person.circle.fill",
                                isSelected: selectedRole == .patient,
                                action: {
                                    selectedRole = .patient
                                    showCodeInput = false
                                    therapistCode = ""
                                    codeError = ""
                                }
                            )
                            
                            // Therapeut Option
                            RoleOptionButton(
                                title: "Therapeut",
                                description: "Termine anderer verwalten",
                                icon: "stethoscope.circle.fill",
                                isSelected: selectedRole == .therapist,
                                action: {
                                    selectedRole = .therapist
                                    showCodeInput = true
                                }
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // ✅ CODE INPUT (NUR FÜR THERAPEUT)
                    if showCodeInput {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Therapeuten-Code")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                SecureField("Code eingeben", text: $therapistCode)
                                    .textContentType(.password)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    .onChange(of: therapistCode) { _, newValue in
                                        // Auto-clear error wenn user tippt
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
                            }
                            
                            Text("Bitte erfrage den Code von deinem Administrator")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    Spacer()
                    
                    // ✅ BUTTONS
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await saveRole()
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Speichern")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.accentColor : Color.gray.opacity(0.5))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                        .disabled(!isFormValid || isLoading)
                        
                        Button {
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Abbrechen")
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
            .navigationTitle("Berechtigungen")
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
    
    // ✅ FORM VALIDATION
    private var isFormValid: Bool {
        switch selectedRole {
        case .patient:
            return true
        case .therapist:
            return !therapistCode.trimmingCharacters(in: .whitespaces).isEmpty
        case .admin:
            return false
        }
    }
    
    // ✅ SAVE LOGIC
    private func saveRole() async {
        isLoading = true
        
        do {
            // Wenn Therapeut: Code validieren
            if selectedRole == .therapist {
                let isCodeValid = await validateTherapistCode(therapistCode)
                if !isCodeValid {
                    codeError = "Ungültiger Code"
                    isLoading = false
                    return
                }
            }
            
            // ✅ DIREKT IN SwiftData aktualisieren
            user.roleRaw = selectedRole.rawValue
            
            try modelContext.save()
            
            // ✅ AuthService currentUser aktualisieren
            authService.currentUser = user
            
            print("✅ Role aktualisiert auf: \(selectedRole.rawValue)")
            
            isLoading = false
            dismiss()
            
        } catch {
            codeError = "Fehler beim Speichern"
            isLoading = false
            print("❌ Fehler: \(error)")
        }
    }
    
    // ✅ CODE VALIDATION
    private func validateTherapistCode(_ code: String) async -> Bool {
        // TODO: Mit deinem Backend kommunizieren
        // Für jetzt: Dummy-Validierung
        return code == "123456"
    }
}
// ✅ ROLE OPTION BUTTON
struct RoleOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .accentColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor : Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}
#Preview {
    let mockUser = User(
        firstName: "Max",
        lastName: "Mustermann",
        email: "test@example.com",
        passwordHash: "hash",
        role: .patient,
        praxisId: nil
    )
    
    // ✅ KORREKTUR: AuthService (nicht MockAuthService)
    let mockAuthService = AuthService(
        authServiceProtocol: MockAuthService(),
        modelContext: nil
    )
    
    // ✅ KORREKTUR: ModelContainer richtig erstellen
    let container = try! ModelContainer(
        for: User.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    RoleEditSheet(user: mockUser)
        .environmentObject(mockAuthService)
        .environment(\.modelContext, container.mainContext)
}
