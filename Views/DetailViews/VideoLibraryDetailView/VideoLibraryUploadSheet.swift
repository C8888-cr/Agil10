
import SwiftUI
import PhotosUI
import SwiftData





struct VideoLibraryUploadSheet: View {
    @ObservedObject var viewModel: VideoLibraryViewModel
    @EnvironmentObject var authService: AuthService
    
    @Environment(\.dismiss) private var dismiss
    
    // Form State
    @State private var title = ""
    @State private var selectedCategory: ExerciseCategory = .mobility
    @State private var selectedBodyRegion: BodyRegion = .fullBody
    @State private var selectedEquipment: Equipment = .noEquipment
    @State private var defaultRepetitions = 3
    @State private var defaultPauseSeconds = 30
    @State private var loopDurationSeconds: Int?
    @State private var useLoopDuration = false
    
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Title
                Section("Video-Titel") {
                    TextField("z.B. Schulter-Mobilisation", text: $title)
                }
                
                // Category
                Section("Übungsart") {
                    Picker("Kategorie", selection: $selectedCategory) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // Body Region
                Section("Körperregion") {
                    Picker("Region", selection: $selectedBodyRegion) {
                        ForEach(BodyRegion.allCases, id: \.self) { region in
                            Label(region.rawValue, systemImage: region.icon)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // Equipment
                Section("Equipment") {
                    Picker("Benötigtes Equipment", selection: $selectedEquipment) {
                        ForEach(Equipment.allCases, id: \.self) { equipment in
                            Label(equipment.rawValue, systemImage: equipment.icon)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
          
          
                
                // Upload Button
                Section {
                    Button {
                        uploadVideo()
                    } label: {
                        HStack {
                            if isUploading {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                            }
                            Text("Video hochladen")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(title.isEmpty || isUploading)
                }
            }
            .navigationTitle("Video hochladen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .disabled(isUploading)
                }
            }
            .alert("Fehler", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(uploadError ?? "Unbekannter Fehler")
            }
        }
    }
    
    // MARK: - Upload Logic
    
     func uploadVideo() {
         
         // ✅ Zuerst User prüfen
               guard let user = authService.currentUser else {
                   uploadError = "Kein Benutzer angemeldet"
                   showError = true
                   return
               }
         
        guard let videoItem = viewModel.selectedVideoItem else {
            uploadError = "Kein Video ausgewählt"
            showError = true
            return
        }
        
        isUploading = true
        
        Task {
            do {
                // 1. Video laden
                guard let movie = try await videoItem.loadTransferable(type: VideoTransferable.self) else {
                    throw VideoStorageError.invalidURL
                }
                
                // 2. Upload durchführen
                let repository = viewModel.repository as? VideoRepository
                _ = try await repository?.uploadVideo(
                    from: movie.url,
                    title: title,
                    category: selectedCategory,
                    bodyRegion: selectedBodyRegion,
                    equipment: selectedEquipment,
                    defaultRepetitions: defaultRepetitions,
                    defaultPauseSeconds: defaultPauseSeconds,
                    loopDurationSeconds: useLoopDuration ? loopDurationSeconds : nil,
                    for: user
                )
                
                // 3. Erfolg - View aktualisieren
                if let user = authService.currentUser {
                    await viewModel.loadVideos(for: user)
                }
                
                // 4. Sheet schließen
                await MainActor.run {
                    dismiss()
                }
                
            } catch let error as VideoStorageError {
                switch error {
                case .fileTooLarge:
                    uploadError = "Das Video ist zu groß. Maximal 200 MB erlaubt."
                case .insufficientSpace:
                    uploadError = "Nicht genügend Speicherplatz verfügbar."
                default:
                    uploadError = error.localizedDescription
                }
                showError = true
            } catch {
                uploadError = "Fehler beim Hochladen: \(error.localizedDescription)"
                showError = true
            }
            
            isUploading = false
        }
    }
}
