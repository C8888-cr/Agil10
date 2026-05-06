//
//  VideoPickerSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//


// Presentation/Shared/Views/VideoPickerSheet.swift
import SwiftUI

struct VideoPickerSheet: View {
    @EnvironmentObject var viewModel: VideoLibraryViewModel
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var themeManager: ThemeManager
    
    let onVideoSelected: (Video) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            contentView
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Übung auswählen")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showFilterSheet = true
                        } label: {
                            Image(systemName: viewModel.hasActiveFilters ?
                                  "line.3.horizontal.decrease.circle.fill" :
                                  "line.3.horizontal.decrease.circle")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(viewModel.hasActiveFilters ? themeManager.currentTheme.accentColor : .primary)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Abbrechen") { dismiss() }
                    }
                }
                .searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Übung suchen..."
                )
                .onChange(of: viewModel.searchText) {
                    viewModel.applyFilters()
                }
                .sheet(isPresented: $showFilterSheet) {
                    FilterSheet(viewModel: viewModel)
                }
                .task {
                    guard let user = session.currentUser else { return }
                    viewModel.setup(for: user)
                }
        }
    }
    
    @State private var showFilterSheet = false
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.filteredVideos.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("Lade Übungen...")
            }
        } else if viewModel.filteredVideos.isEmpty {
            emptyStateView
        } else {
            videoListView
        }
    }
    
    private var videoListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.hasActiveFilters {
                    activeFiltersBar
                }
                
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredVideos) { video in
                        VideoListRow(
                            video: video,
                            onTap: { video in
                                onVideoSelected(video)
                                dismiss()
                            },
                            onFavorite: {
                                Task {
                                    if let user = session.currentUser {
                                        await viewModel.toggleFavorite(video, for: user)
                                    }
                                }
                            },
                            onDelete: nil
                        )
                        .padding(.horizontal, 16) 
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("Keine Übungen vorhanden")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.hasActiveFilters ?
                 "Keine Übungen entsprechen den Filtern" :
                 "Lade zuerst Übungen in deine Mediathek hoch")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if viewModel.hasActiveFilters {
                Button("Filter zurücksetzen") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = viewModel.selectedCategory {
                    FilterChip(title: category.rawValue, icon: category.icon) {
                        viewModel.selectedCategory = nil
                        viewModel.applyFilters()
                    }
                }
                if let region = viewModel.selectedBodyRegion {
                    FilterChip(title: region.rawValue, icon: region.icon) {
                        viewModel.selectedBodyRegion = nil
                        viewModel.applyFilters()
                    }
                }
                if let equipment = viewModel.selectedEquipment {
                    FilterChip(title: equipment.rawValue, icon: equipment.icon) {
                        viewModel.selectedEquipment = nil
                        viewModel.applyFilters()
                    }
                }
                if viewModel.showFavoritesOnly {
                    FilterChip(title: "Favoriten", icon: "star.fill") {
                        viewModel.showFavoritesOnly = false
                        viewModel.applyFilters()
                    }
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
}
