//
//  VideoPickerSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//

import SwiftUI
import AgilCore


struct VideoPickerSheet: View {
    @EnvironmentObject var viewModel: VideoLibraryViewModel
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var themeManager: ThemeManager
    
    let onVideoSelected: (Video) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var showFilterSheet = false
    
    // ✅ NEU: für Inline-Preview
    @State private var currentlyPlayingId: UUID? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ NEU: Custom Searchbar mit Filter rechts daneben
                customSearchBar
                
                contentView
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // ✅ NEU: Zurück-Pfeil links
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text("")
                        }
                        .foregroundStyle(themeManager.currentTheme.accentColor)
                    }
                }
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
    
    // MARK: - Custom Searchbar
    
    private var customSearchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Übung suchen...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.searchText) {
                        viewModel.applyFilters()
                    }
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                        viewModel.applyFilters()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
            
            // Filter-Button direkt rechts
            Button {
                showFilterSheet = true
            } label: {
                Image(systemName: viewModel.hasActiveFilters ?
                      "line.3.horizontal.decrease.circle.fill" :
                      "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(viewModel.hasActiveFilters ? themeManager.currentTheme.accentColor : .primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.filteredVideos.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("Lade Übungen...")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                currentlyPlayingId = nil
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
                            onDelete: nil,
                            isPreviewPlaying: currentlyPlayingId == video.id,
                            onPreviewTap: {
                                togglePreview(for: video.id)
                            }
                        )
                        .padding(.horizontal, 16)
                        .onDisappear {
                            if currentlyPlayingId == video.id {
                                currentlyPlayingId = nil
                            }
                        }
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
    
    // MARK: - Preview Helper
    
    private func togglePreview(for videoId: UUID) {
        if currentlyPlayingId == videoId {
            currentlyPlayingId = nil
        } else {
            currentlyPlayingId = videoId
        }
    }
}
