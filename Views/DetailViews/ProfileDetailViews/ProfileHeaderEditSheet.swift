//
//  ProfileHeaderEditSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 18.02.26.
//
import SwiftUI
import SwiftData
import PhotosUI



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
    @State private var imageSelection: PhotosPickerItem?
    
    
    
    let user: User
    
    init(user: User) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        
        // ✅ BILD LADEN
               if let imageData = user.profileImage {
                   _selectedImage = State(initialValue: UIImage(data: imageData))
               }
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
                                        .overlay(
                                            Text(user.initials)
                                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color.accentColor)
                                        )
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
                                .photosPicker(
                                    isPresented: $showImagePicker,
                                    selection: $imageSelection,
                                    matching: .images
                                )
                                .onChange(of: imageSelection) { oldValue, newValue in
                                    Task {
                                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                                           let image = UIImage(data: data) {
                                            selectedImage = image
                                        }
                                    }
                                }
                                
                            Text("Profilbild ändern")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        
                        // ✅ VORNAME SECTION
                        InfoCard {
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(Color.accentColor.opacity(0.7))
                                    
                                    TextField(firstName.isEmpty ? "Vorname" : firstName, text: $firstName)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                            }
                        }
                        // ✅ NACHNAME SECTION
                        InfoCard {
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(Color.accentColor.opacity(0.7))
                                    
                                    TextField(lastName.isEmpty ? "Nachname" : lastName, text: $lastName)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                            }
                        }
                        
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
        
        // ✅ BILD SPEICHERN
           if let selectedImage = selectedImage,
              let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
               user.profileImage = imageData
           }
        
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
#Preview {
    let mockUser = User(
        id: UUID(),
        firstName: "Max",
        lastName: "Mustermann",
        email: "max@example.com",
        passwordHash: "mock",
        role: .patient,
        praxisId: nil
    )
    
    let authService = AuthService(authServiceProtocol: MockAuthService())
    
    ProfileHeaderEditSheet(user: mockUser)
        .environmentObject(authService)
        .modelContainer(for: User.self, inMemory: true)
}
