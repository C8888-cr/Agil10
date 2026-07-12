
import SwiftUI
import PhotosUI
import SwiftData
import AgilCore

struct LibraryView: View {
    
    @EnvironmentObject var session: SessionManager
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var viewModel: VideoLibraryViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showPlayer = false
    @State private var showFilterSheet = false
    @State private var selectedVideo: Video?
    @State private var pickerPresented = false
    @State private var showProfile = false
    @State private var showSettings = false
    
    @State private var showCamera = false
    
    @State private var currentlyPlayingId: UUID? = nil
    
    
    var onVideoSelected: ((Video) -> Void)? = nil
    
    
    // ✅ NEU
    init(onVideoSelected: ((Video) -> Void)? = nil) {
        self.onVideoSelected = onVideoSelected
    }
    
    
    private var currentUser: User? {
        session.currentUser
       }
    var body: some View {
        
        
        contentView
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .toolbar {
                toolbarContent
            }
        // Sheet hinzufügen:
            .fullScreenCover(isPresented: $showCamera) {
                        PortraitLockedView {
                            CameraVideoPickerView { url in
                                viewModel.handleCameraVideo(url: url)
                            }
                        }
                        .ignoresSafeArea()
                    }
        
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Übungen suchen..."
            )
            .onChange(of: viewModel.searchText) {
                viewModel.applyFilters()
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showUploadSheet) {
                uploadSheet
            }
            .alert("Fehler", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unbekannter Fehler")
            }
        
        
            .photosPicker(
                isPresented: $pickerPresented,
                selection: $viewModel.selectedVideoItem,
                matching: .videos
            )
            .onChange(of: viewModel.selectedVideoItem) {
                viewModel.handleVideoSelection()
                pickerPresented = false
            }
            .task {
                await setupView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(session)
                    .environment(\.modelContext, profileVM.modelContext)
            }
           
    }
    
    
    // MARK: - Content Views
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.filteredVideos.isEmpty {
            loadingView
        } else if viewModel.filteredVideos.isEmpty {
            emptyStateView
        } else {
            videoContentView
        }
    }
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Lade Übungen...")
            Text("Debug: \(viewModel.filteredVideos.count) Übungen geladen")
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
    @ViewBuilder
    private var uploadSheet: some View {
        if session.currentUser != nil {
            VideoLibraryUploadSheet(viewModel: viewModel)
                .environmentObject(session)
        }
    }
    
    
 
    
    
    private func setupView() async {
        print("🔍 Task gestartet")
        print("📦 ModelContext: \(modelContext)")
        print("👤 AuthService User: \(session.currentUser?.id.uuidString ?? "NIL")")
        print("📹 ViewModel: \(viewModel)")
        print("🎬 Videos Count: \(viewModel.filteredVideos.count)")
        
        guard let user = session.currentUser else {
            print("❌ Kein User vorhanden!")
            return
        }
        
        print("🔍 Task gestartet für User: \(user.email)")
        await DatabaseHealthService.shared.performHealthCheck(context: modelContext)
        
        viewModel.setup(for: user)
        
        print("🏁 Setup fertig: \(viewModel.filteredVideos.count) Videos")
    }
    
    
    
    @ViewBuilder
    var videoContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.hasActiveFilters {
                    activeFiltersBar
                }
                
                storageInfoCard
                    .padding(.horizontal, 16)
                
                videoListView
            }
            .padding(.top, 8)
        }
        .refreshable {
            if let user = session.currentUser {
                await viewModel.loadVideos(for: user)
            }
        }
    }
    
    
    
    var videoListView: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.filteredVideos) { video in
                VideoListRow(
                    video: video,
                    onTap: { video in
                        currentlyPlayingId = nil   // beim Auswählen stoppen
                        print("🎬 onTap Closure aufgerufen für: \(video.title)")
                        if let onVideoSelected = onVideoSelected {
                            print("✅ onVideoSelected existiert, rufe auf...")
                            onVideoSelected(video)
                            print("✅ onVideoSelected aufgerufen!")
                        } else {
                            print("❌ onVideoSelected ist NIL!")
                            selectedVideo = video
                        }
                    },
                    onFavorite: {
                        Task {
                            if let user = session.currentUser {
                                await viewModel.toggleFavorite(video, for: user)
                            }
                        }
                    },
                    onDelete: {
                        Task {
                            if let user = session.currentUser {
                               viewModel.deleteVideo(video, for: user)
                            }
                        }
                    },
                    // ✅ NEU:
                    isPreviewPlaying: currentlyPlayingId == video.id,
                    onPreviewTap: {
                        togglePreview(for: video.id)
                    }
                )
                .padding(.horizontal, 16)
                // ✅ Auto-Stop beim Wegscrollen
                .onDisappear {
                    if currentlyPlayingId == video.id {
                        currentlyPlayingId = nil
                    }
                }
                
                if video.id != viewModel.filteredVideos.last?.id {
                   
                }
            }
        }
    }

    // ✅ NEU: irgendwo unten in der View hinzufügen
    private func togglePreview(for videoId: UUID) {
        if currentlyPlayingId == videoId {
            currentlyPlayingId = nil
        } else {
            currentlyPlayingId = videoId
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("Keine Übungen vorhanden")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.hasActiveFilters ?
                 "Keine Übungen entsprechen den Filtern" :
                    "Lade dein erstes Übungsvideo hoch")
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            
            if viewModel.hasActiveFilters {
                Button("Filter zurücksetzen") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.bordered)
            } else {
                Button(action: { pickerPresented = true }) {
                    Label("Übung hochladen", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = viewModel.selectedCategory {
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        onRemove: { viewModel.selectedCategory = nil
                            viewModel.applyFilters()}
                    )
                }
                
                if let region = viewModel.selectedBodyRegion {
                    FilterChip(
                        title: region.rawValue,
                        icon: region.icon,
                        onRemove: { viewModel.selectedBodyRegion = nil
                            viewModel.applyFilters()}
                    )
                }
                
                if let equipment = viewModel.selectedEquipment {
                    FilterChip(
                        title: equipment.rawValue,
                        icon: equipment.icon,
                        onRemove: { viewModel.selectedEquipment = nil
                            viewModel.applyFilters()}
                    )
                }
                
                if viewModel.showFavoritesOnly {
                    FilterChip(
                        title: "Favoriten",
                        icon: "star.fill",
                        onRemove: { viewModel.showFavoritesOnly = false
                            viewModel.applyFilters()}
                    )
                }
                
                Button("Alle Filter löschen") {
                    viewModel.clearFilters()
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
            .padding(.horizontal, 16)
        }
    }
    
    
    
    var storageInfoCard: some View {
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Speicher")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(viewModel.storageUsed) von \(viewModel.storageAvailable)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Text("\(viewModel.filteredVideos.count) Übungen")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.accentColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    
    
    
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        // LINKS: Plus + Filter
        ToolbarItem(placement: .topBarLeading) {
            HStack(spacing: 12) {
                Menu {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Übung aufnehmen", systemImage: "camera.fill")
                        }
                    }
                    Button {
                        pickerPresented = true
                    } label: {
                        Label("Aus Mediathek", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .font(.title3)
                }
             
   
                // Filter-Button
                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ?
                          "line.3.horizontal.decrease.circle.fill" :
                          "line.3.horizontal.decrease.circle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(viewModel.hasActiveFilters ? themeManager.currentTheme.accentColor : .primary)
                    .font(.title3)
                }
            }
        }
        
        
        
        // RECHTS: Profile-Menü
        ToolbarItem(placement: .topBarTrailing) {
          
                Button {
                    showProfile = true
                
        
            } label: {
                // ✅ PROFILBILD STATT ICON
                           if let user = session.currentUser,
                              let imageData = user.profileImage,
                              let uiImage = UIImage(data: imageData) {
                               Image(uiImage: uiImage)
                                   .resizable()
                                   .scaledToFill()
                                   .frame(width: 35, height: 35)
                                   .clipShape(Circle())
                           } else {
                               Circle()
                                   .fill(Color.accentColor.opacity(0.3))
                                   .frame(width: 35, height: 35)
                                   .overlay(
                                       Text(session.currentUser?.initials ?? "?")
                                           .font(.system(size: 14, weight: .bold))
                                           .foregroundStyle(themeManager.currentTheme.accentColor)
                                   )
                           }
            }
        }
    }

}
// MARK: - FilterChip
struct FilterChip: View {
    let title: String
    let icon: String
    let onRemove: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(themeManager.currentTheme.accentColor.opacity(0.1))
        .foregroundStyle(themeManager.currentTheme.accentColor)
        .clipShape(Capsule())
    }
}

