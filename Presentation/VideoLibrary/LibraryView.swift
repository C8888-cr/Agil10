
import SwiftUI
import PhotosUI
import SwiftData


struct LibraryView: View {
    
    @EnvironmentObject var authService: AuthService
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var viewModel: VideoLibraryViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    

    @State private var showPlayer = false
    @State private var showFilterSheet = false
    @State private var selectedVideo: Video?
    @State private var pickerPresented = false
    @State private var showProfile = false
    @State private var showSettings = false
    
    @State private var showCamera = false
    

    var onVideoSelected: ((Video) -> Void)? = nil
    
    
    // ✅ NEU
    init(onVideoSelected: ((Video) -> Void)? = nil) {
        self.onVideoSelected = onVideoSelected
    }
    
    
    private var currentUser: User? {
           authService.currentUser
       }
    var body: some View {
        
        
        contentView
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Video-Bibliothek")
            .toolbar {
                toolbarContent
            }
        // Sheet hinzufügen:
        .fullScreenCover(isPresented: $showCamera) {
            CameraVideoPickerView { url in
                viewModel.handleCameraVideo(url: url)
            }
        }
        
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Videos suchen..."
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
                    .environmentObject(authService)
                    .environment(\.modelContext, profileVM.modelContext)
            }
            .sheet(isPresented: $showSettings) {
                settingsSheet
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
            Text("Lade Videos...")
            Text("Debug: \(viewModel.filteredVideos.count) Videos geladen")
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
    @ViewBuilder
    private var uploadSheet: some View {
        if authService.currentUser != nil {
            VideoLibraryUploadSheet(viewModel: viewModel)  
        }
    }
    
    
    private var settingsSheet: some View {
        SettingsView()
            .environmentObject(settingsVM)
            .environment(\.modelContext, modelContext)
    }
    
    
    
    private func setupView() async {
        print("🔍 Task gestartet")
        print("📦 ModelContext: \(modelContext)")
        print("👤 AuthService User: \(authService.currentUser?.id.uuidString ?? "NIL")")
        print("📹 ViewModel: \(viewModel)")
        print("🎬 Videos Count: \(viewModel.filteredVideos.count)")
        
        guard let user = authService.currentUser else {
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
            if let user = authService.currentUser {
                await viewModel.loadVideos(for: user)
            }
        }
    }
    
    
    
    var videoListView: some View {
        LazyVStack(spacing: 4) {
            ForEach(viewModel.filteredVideos) { video in
                VideoListRow(
                    video: video,
                    
                    onTap: { video in
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
                            if let user = authService.currentUser {
                                await viewModel.toggleFavorite(video, for: user)
                            }
                        }
                    },
                    onDelete: {
                        Task {
                            if let user = authService.currentUser {
                               viewModel.deleteVideo(video, for: user)
                            }
                        }
                    }
                    )
                if video.id != viewModel.filteredVideos.last?.id {
                   
                }
            }
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("Keine Videos vorhanden")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.hasActiveFilters ?
                 "Keine Videos entsprechen den Filtern" :
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
                    Label("Video hochladen", systemImage: "plus.circle.fill")
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
            
            Text("\(viewModel.filteredVideos.count) Videos")
                .font(.headline)
                .foregroundStyle(.accent)
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
                            Label("Video aufnehmen", systemImage: "camera.fill")
                        }
                    }
                    Button {
                        pickerPresented = true
                    } label: {
                        Label("Aus Bibliothek", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                }
                
   
                // Filter-Button
                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ?
                          "line.3.horizontal.decrease.circle.fill" :
                          "line.3.horizontal.decrease.circle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(viewModel.hasActiveFilters ? .accent : .primary)
                }
            }
        }
        
        
        
        // RECHTS: Profile-Menü
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Profil") {
                    showProfile = true
                }
                Button("Einstellungen") {
                   showSettings = true
                }
            } label: {
                // ✅ PROFILBILD STATT ICON
                           if let user = authService.currentUser,
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
                                       Text(authService.currentUser?.initials ?? "?")
                                           .font(.system(size: 14, weight: .bold))
                                           .foregroundStyle(Color.accentColor)
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
        .background(Color.accent.opacity(0.1))
        .foregroundStyle(.accent)
        .clipShape(Capsule())
    }
}

