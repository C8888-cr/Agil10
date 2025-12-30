//
//  VideoLibraryViewModel.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//



import Foundation
import SwiftUI
import PhotosUI
@MainActor
final class VideoLibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var allVideos: [Video] = []  // ✅ Renamed from 'videos'
    @Published var filteredVideos: [Video] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Filters
    @Published var selectedCategory: ExerciseCategory?
    @Published var selectedBodyRegion: BodyRegion?
    @Published var selectedEquipment: Equipment?
    @Published var searchText = ""
    @Published var showFavoritesOnly = false
    
    // Upload
    @Published var showUploadSheet = false
    @Published var selectedVideoItem: PhotosPickerItem?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    // View Mode
    @Published var viewMode: ViewMode = .grid
    
    // Storage Info
    @Published var storageUsed: String = "0 MB"
    @Published var storageAvailable: String = "0 GB"
    
    enum ViewMode {
        case grid, list
    }
    
    // MARK: - Dependencies
    let repository: VideoRepositoryProtocol
    private let storageService: VideoStorageService
   
    
    // MARK: - Init
    init(
           repository: VideoRepositoryProtocol,

           storageService: VideoStorageService = .shared
       ) {
           self.repository = repository
    
           self.storageService = storageService
       }
    
    
    // ✅ AuthService aus AppDependencies holen
       private var authService: AuthService {
           AppDependencies.shared.authService
       }
       
       // ✅ Dann currentUser daraus holen
       private var currentUser: User? {
           authService.currentUser
       }
    
    
    
    
    
    // MARK: - Setup
    func setup(for user: User) {
        print("🟢 START: Setup ViewModel")
     
        Task {
            await loadVideos(for: user)
            updateStorageInfo()
        }
        print("✅ Setup abgeschlossen")
    }
    
    // MARK: - Load Videos
    func loadVideos(for user: User) async {
          print("📱 Loading videos for user: \(user.email)")
          isLoading = true
          defer {
              isLoading = false
              print("📱 Loading complete: \(allVideos.count) videos")
          }
        
        
        do {
            // ✅ Safe fetch with corruption handling
            let videos = try await repository.fetchAllVideos(for: user)
            print("📱 ✅ \(videos.count) Videos geladen!")
            // ✅ Filter videos where files actually exist
            var validVideos: [Video] = []
            var orphanedVideos: [Video] = []
            
            for video in videos {
                do {
                    _ = try await VideoSourceManager.shared.getVideoURL(for: video)
                    validVideos.append(video)
                } catch {
                    print("⚠️ Video file missing: \(video.title)")
                    orphanedVideos.append(video)
                }
            }
            
            // ✅ Delete orphaned database entries
            if !orphanedVideos.isEmpty {
                print("🗑️ Cleaning up \(orphanedVideos.count) orphaned videos")
                for video in orphanedVideos {
                    try? await repository.deleteVideo(metadata: video)
                }
            }
            
            self.allVideos = validVideos
            applyFilters()
            calculateStorage()
            
            print("✅ Loaded \(validVideos.count) valid videos")
            if !orphanedVideos.isEmpty {
                print("⚠️ Removed \(orphanedVideos.count) orphaned entries")
            }
            
        } catch {
            print("❌ Load error: \(error)")
            errorMessage = "Videos konnten nicht geladen werden: \(error.localizedDescription)"
            showError = true
        }
    }
    
    
    // MARK: - Filters
    func applyFilters() {
        var filtered = allVideos
        
        // Category Filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Body Region Filter
        if let bodyRegion = selectedBodyRegion {
            filtered = filtered.filter { $0.bodyRegion == bodyRegion }
        }
        
        // Equipment Filter
        if let equipment = selectedEquipment {
            filtered = filtered.filter { $0.equipment == equipment }
        }
        
        // Search Filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Favorites Filter
        if showFavoritesOnly {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        filteredVideos = filtered
        print("📊 Filtered: \(filtered.count) of \(allVideos.count) videos")
    }
    
    func clearFilters() {
        selectedCategory = nil
        selectedBodyRegion = nil
        selectedEquipment = nil
        searchText = ""
        showFavoritesOnly = false
        applyFilters()
    }
    
    var hasActiveFilters: Bool {
        selectedCategory != nil ||
        selectedBodyRegion != nil ||
        selectedEquipment != nil ||
        !searchText.isEmpty ||
        showFavoritesOnly
    }
    
    // MARK: - Toggle Favorite
    func toggleFavorite(_ video: Video, for user: User) async {
        Task {
            do {
                // ✅ Check if video still exists
                guard allVideos.contains(where: { $0.id == video.id }) else {
                    print("⚠️ Video not found in array")
                    await loadVideos(for: user)
                    return
                }
                
                let updatedVideo = video
                updatedVideo.isFavorite.toggle()
                
                try await repository.updateVideo(metadata: updatedVideo)
                
                // ✅ UI Update
                if let index = allVideos.firstIndex(where: { $0.id == video.id }) {
                    allVideos[index] = updatedVideo
                }
                applyFilters()
                
                print("✅ Favorite toggled: \(video.title)")
            } catch {
                print("❌ Toggle favorite error: \(error)")
                await loadVideos(for: user)
            }
        }
    }
    
    // MARK: - Delete Video
    func deleteVideo(_ video: Video, for user: User) {
        Task {
            do {
                // ✅ Erst aus UI entfernen
                allVideos.removeAll { $0.id == video.id }
                filteredVideos.removeAll { $0.id == video.id }
                
                // ✅ Dann aus DB löschen
                try await repository.deleteVideo(metadata: video)
                
                // ✅ Storage neu berechnen
                calculateStorage()
                
                print("✅ Video deleted: \(video.title)")
            } catch {
                print("❌ Delete error: \(error)")
                errorMessage = "Video konnte nicht gelöscht werden"
                showError = true
                
                // ✅ Bei Fehler: Videos neu laden
                await loadVideos(for: user)
            }
        }
    }
    
    // MARK: - Upload Video
    func handleVideoSelection() {
        guard let item = selectedVideoItem else { return }
        
        Task {
            isUploading = true
            uploadProgress = 0.0
            defer { isUploading = false }
            
            do {
                // 1. Video laden
                guard let movie = try await item.loadTransferable(type: VideoTransferable.self) else {
                    errorMessage = "Video konnte nicht geladen werden"
                    showError = true
                    return
                }
                
                uploadProgress = 0.5
                
                // 2. Upload-Sheet öffnen für weitere Details
                showUploadSheet = true
                
                uploadProgress = 1.0
                
                print("✅ Video loaded: \(movie.url)")
                
            } catch {
                errorMessage = "Fehler beim Video-Import: \(error.localizedDescription)"
                showError = true
                print("❌ Video import error: \(error)")
            }
        }
    }
    
    // MARK: - Storage Info
    func updateStorageInfo() {
        let info = storageService.getStorageInfo()
        storageUsed = info.used
        storageAvailable = info.available
    }
    
    func calculateStorage() {
        let totalBytes = allVideos.reduce(0) { $0 + $1.fileSizeBytes }
        let totalMB = Double(totalBytes) / 1_048_576.0
        
        if totalMB < 1024 {
            storageUsed = String(format: "%.1f MB", totalMB)
        } else {
            storageUsed = String(format: "%.2f GB", totalMB / 1024.0)
        }
        
        // Available storage (example: 5 GB)
        storageAvailable = "5 GB"
    }
}
// MARK: - Video Transferable (für PhotosPicker)
struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copy = URL.temporaryDirectory.appending(path: "import_\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

