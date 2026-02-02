import SwiftUI
import SwiftData
struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.modelContext) var modelContext
    // ✅ Einfach: User kommt direkt vom AuthService
       private var currentUser: User? {
           authService.currentUser
       }
    
    
  
    
    @State private var isEditing = false
    @State private var editFirstName = ""
    @State private var editLastName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // ✅ Nutze Published Property vom ViewModel
                if let user = currentUser {
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
                    ContentUnavailableView(
                        "Kein Profil",
                        systemImage: "person.circle.fill",
                        description: Text("Bitte einloggen, um dein Profil zu sehen.")
                    )
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
                debugUserInDatabase()
            }
        }
    }
    
    // MARK: - Actions
       private func startEditing() {
           guard let user = currentUser else { return }
           editFirstName = user.firstName
           editLastName = user.lastName
           isEditing = true
       }
       
    private func saveChanges() {
        do {
            try authService.updateUser(
                firstName: editFirstName,
                lastName: editLastName
            )
            print("✅ Profil gespeichert!")
        } catch {
            print("❌ Fehler: \(error)")
        }
        
        isEditing = false
    }
    
    
       private func resetEditFields() {
           guard let user = currentUser else {
               editFirstName = ""
               editLastName = ""
               return
           }
           editFirstName = user.firstName
           editLastName = user.lastName
       }
    private func debugUserInDatabase() {
        guard let user = currentUser else { return }
        let userId = user.id
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
        )
        
        if let dbUser = try? modelContext.fetch(descriptor).first {
            print("🔍 DEBUG User in DB:")
            print("   firstName: \(dbUser.firstName)")
            print("   lastName: \(dbUser.lastName)")
            print("   fullName: \(dbUser.fullName)")
        } else {
            print("❌ User nicht in DB gefunden")
        }
    }
   }
