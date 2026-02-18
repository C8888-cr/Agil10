// MARK: - ProfileHeaderEditSheet
struct ProfileHeaderEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var authService: AuthService
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let user: User
    
    init(user: User) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // ✅ AVATAR SECTION
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                // Avatar
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.accentColor.opacity(0.3),
                                                    Color.accentColor.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                    
                                    Text(user.initials)
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.accentColor)
                                }
                                
                                // Edit Button
                                Button {
                                    showImagePicker = true
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.accentColor)
                                        .background(Circle().fill(Color(.systemBackground)).frame(width: 44, height: 44))
                                }
                            }
                            .frame(height: 120)
                            
                            Text("Profilbild ändern")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        
                        // ✅ FORM SECTION
                        VStack(spacing: 16) {
                            // Vorname
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Vorname", systemImage: "person.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                TextField("Vorname", text: $firstName)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.givenName)
                            }
                            
                            // Nachname
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Nachname", systemImage: "person.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                TextField("Nachname", text: $lastName)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.familyName)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // ✅ ERROR MESSAGE
                        if let errorMessage = errorMessage {
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text(errorMessage)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Profil bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        saveChanges()
                    }
                    .disabled(isLoading || firstName.isEmpty || lastName.isEmpty)
                }
            }
            .fileImporter(
                isPresented: $showImagePicker,
                allowedContentTypes: [.image],
                onCompletion: { result in
                    handleImageSelection(result)
                }
            )
        }
    }
    
    // MARK: - Actions
    private func saveChanges() {
        isLoading = true
        errorMessage = nil
        
        // Update im modelContext
        user.firstName = firstName
        user.lastName = lastName
        
        // TODO: Profilbild speichern (Backend/Storage)
        
        do {
            try modelContext.save()
            print("✅ Profil aktualisiert!")
            dismiss()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func handleImageSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        case .failure(let error):
            errorMessage = "Fehler beim Laden des Bildes: \(error.localizedDescription)"
        }
    }
}