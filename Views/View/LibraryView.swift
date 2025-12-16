
import SwiftUI
import PhotosUI
import SwiftData
struct LibraryView: View {
    
    @EnvironmentObject var appState: AppState
    
    
    @State private var showPlayer = false
    @State private var showFilterSheet = false
    @State private var selectedVideo: Video?
    @State private var pickerPresented = false
    @State private var showProfile = false
    @State private var showSettings = false
    
    @StateObject private var viewModel: VideoLibraryViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settingsVM: SettingsViewModel
    

    var onVideoSelected: ((Video) -> Void)? = nil
    
    init(repository: VideoRepositoryProtocol,
         onVideoSelected: ((Video) -> Void)? = nil) {
        self.onVideoSelected = onVideoSelected
        _viewModel = StateObject(wrappedValue: VideoLibraryViewModel(repository: repository))
    }
    
    var body: some View {
     
            ZStack {
                if viewModel.isLoading && viewModel.filteredVideos.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Lade Videos...")
                        Text("Debug: \(viewModel.filteredVideos.count) Videos geladen")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                } else if viewModel.filteredVideos.isEmpty {
                    emptyStateView
                } else {
                    videoContentView
                }
            }
            .navigationTitle("Video-Bibliothek")
            .toolbar {
                toolbarContent
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
                VideoUploadSheet(viewModel: viewModel)
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
                print("🔍 Task gestartet")
                await DatabaseHealthService.shared.performHealthCheck(context: modelContext)
                print("✅ Health Check fertig")
                viewModel.setup()
            }
            .onAppear {
                print("🔍 VideoLibraryView onAppear - User: \(currentUser.id)")
                viewModel.setup()
            }
            .sheet(isPresented: $showProfile) {
                   ProfileView()
               }
               .sheet(isPresented: $showSettings) {
                   SettingsView()  // oder settingsVM.user falls verfügbar
                       .environmentObject(settingsVM)  // falls SettingsView das braucht
                       .environment(\.modelContext, modelContext)
               
        }
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
            await viewModel.loadVideos()
        }
    }
    
    var videoListView: some View {
        LazyVStack(spacing: 0) {
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
                    
                    
                    /*   VideoListRow(
                     video: video,
                     onTap: {
                     if let onVideoSelected = onVideoSelected {
                     onVideoSelected(video)
                     } else {
                     selectedVideo = video
                     }
                     },
                     
                     */
                    
                    onFavorite: { viewModel.toggleFavorite(video) },
                    onDelete: { viewModel.deleteVideo(video) }
                )
                
                if video.id != viewModel.filteredVideos.last?.id {
                    Divider()
                        .padding(.leading, 116)
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
                        onRemove: { viewModel.selectedCategory = nil }
                    )
                }
                
                if let region = viewModel.selectedBodyRegion {
                    FilterChip(
                        title: region.rawValue,
                        icon: region.icon,
                        onRemove: { viewModel.selectedBodyRegion = nil }
                    )
                }
                
                if let equipment = viewModel.selectedEquipment {
                    FilterChip(
                        title: equipment.rawValue,
                        icon: equipment.icon,
                        onRemove: { viewModel.selectedEquipment = nil }
                    )
                }
                
                if viewModel.showFavoritesOnly {
                    FilterChip(
                        title: "Favoriten",
                        icon: "star.fill",
                        onRemove: { viewModel.showFavoritesOnly = false }
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
                .foregroundStyle(.blue)
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
                // Plus-Button
                Button(action: { pickerPresented = true }) {
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
                    .foregroundStyle(viewModel.hasActiveFilters ? .blue : .primary)
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
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
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
        .background(Color.blue.opacity(0.1))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }
}
// MARK: - Preview
#Preview {
    let container = PreviewHelper.createModelContainer()
    let context = ModelContext(container)
    
    let testUser = User(
        id: UUID(),
        email: "test@example.com",
        passwordHash: "hashedPassword123"
    )
    let settingsVM = SettingsViewModel(modelContext: context)
 
                                       
    LibraryView(repository: VideoRepository(modelContext: context))
      
    .modelContainer(container)
    .environmentObject(settingsVM)
}
