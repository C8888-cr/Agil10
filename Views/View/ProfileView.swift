import SwiftUI
import SwiftData


struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.modelContext) var modelContext
    
    @StateObject private var profileVM: ProfileViewModel

      init(profileVM: ProfileViewModel) {
          self._profileVM = StateObject(wrappedValue: profileVM)
      }
    @State private var isEditing = false
    @State private var editFirstName = ""
    @State private var editLastName = ""
    var user: User? {
        profileVM.currentUserInContext
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let user = user {  // 🛠️ Sicherstellen, dass der Benutzer verfügbar ist
                    // Persönliche Daten
                    Section("Persönliche Daten") {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(.blue.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                Text(user.initials)
                                    .font(.headline.bold())
                                    .foregroundStyle(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if isEditing {
                                    TextField("Vorname", text: $editFirstName)
                                        .textFieldStyle(.roundedBorder)
                                    TextField("Nachname", text: $editLastName)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    Text(user.fullName)
                                        .font(.headline)
                                    if let age = user.age {
                                        Text("\(age) Jahre")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Kontaktinformationen
                    Section("Kontakt") {
                        LabeledContent("E-Mail") {
                            Text(user.email)
                                .font(.body.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                    
                    // Rolle
                    Section("Rolle") {
                        HStack {
                            Label("Rolle", systemImage: "person.2")
                            Spacer()
                            Text(user.role.rawValue.capitalized)
                                .font(.subheadline.bold())
                        }
                    }
                    
                    // Account Status
                    Section("Account") {
                        HStack {
                            Label("Status", systemImage: "crown")
                            Spacer()
                            Text(user.isPremium ? "PREMIUM" : "Free")
                                .font(.headline.bold())
                        }
                        LabeledContent("Mitglied seit") {
                            Text(user.createdAt, style: .date)
                                .font(.caption)
                        }
                    }
                    
                    // Aktionen
                    Section {
                        if isEditing {
                            Button("Speichern") {
                                saveChanges()
                            }
                            .buttonStyle(.borderedProminent)
                            Button("Abbrechen") {
                                isEditing = false
                                resetEditFields()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Bearbeiten") {
                                startEditing()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                } else {
                    ContentUnavailableView("Kein Profil",
                                    systemImage: "person",
                                    description: Text("Bitte einloggen."))
                }
            }
            .navigationTitle("Mein Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout") {
                        Task {
                            await authService.logout()
                        }
                    }
                }
            }
            .onAppear {
                resetEditFields()
            }
        }
    }
    
    // MARK: - Actions
    private func startEditing() {
        guard let user = user else { return }
        editFirstName = user.firstName
        editLastName = user.lastName
        isEditing = true
    }
    
    private func saveChanges() {
        guard let user = user else { return }
        
        user.firstName = editFirstName
        user.lastName = editLastName
        
        isEditing = false
    }
    
    private func resetEditFields() {
        guard let user = user else { return }
        editFirstName = user.firstName
        editLastName = user.lastName
    }
}
