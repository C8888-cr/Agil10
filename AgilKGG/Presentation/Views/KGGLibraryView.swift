//
//  KGGLibraryView.swift
//  AgilKGG
//
//  Übungsbibliothek: Suche ganz oben, darunter der wiederverwendbare
//  Filterbereich (KGGLibraryFilterView), große Cards mit Thumbnail.
//

import SwiftUI
import SwiftData
import PhotosUI
import Combine
import AgilCore

struct KGGLibraryView: View {
    @StateObject private var viewModel: KGGLibraryViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showAddSheet = false

    private var accent: Color { themeManager.currentTheme.accentColor }

    init(modelContext: ModelContext, praxisId: UUID) {
        _viewModel = StateObject(wrappedValue: KGGLibraryViewModel(modelContext: modelContext, praxisId: praxisId))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                searchBar
                KGGLibraryFilterView(viewModel: viewModel, accent: accent)

                if viewModel.isLoading && viewModel.exercises.isEmpty {
                    Spacer(); ProgressView(); Spacer()
                } else if viewModel.filteredExercises.isEmpty {
                    emptyState
                } else {
                    listView
                }
            }

            if viewModel.isImporting { importOverlay }
        }
        .navigationTitle("Übungen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(accent)
                }
            }
            ToolbarItem(placement: .topBarTrailing) { KGGLogoMenu() }
        }
        .fullScreenCover(isPresented: $showAddSheet) {
            KGGAddLibraryExerciseView(viewModel: viewModel)
                .environmentObject(themeManager)
        }
        .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.load() }
    }

    // MARK: - Suchleiste (ganz oben)

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Übung suchen", text: $viewModel.searchText)
                .autocorrectionDisabled()
            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Liste

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredExercises) { exercise in
                    exerciseCard(exercise)
                }
            }
            .padding(16)
        }
    }

    private func exerciseCard(_ exercise: KGGLibraryExercise) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if let data = exercise.thumbnailData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                } else {
                    Rectangle().fill(Color(.systemGray5)).frame(height: 180)
                    VStack(spacing: 8) {
                        Image(systemName: exercise.hasVideo ? "play.circle.fill" : "video.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(exercise.hasVideo ? accent : .secondary)
                        if !exercise.hasVideo {
                            Text("Kein Video").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                if exercise.hasVideo && exercise.thumbnailData != nil {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(radius: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 4) {
                    infoLine("Muskel", exercise.muskel)
                    infoLine("Gelenk", exercise.gelenk)
                    infoLine("Trainingsgerät", exercise.geraet)
                    infoLine("Bewegung", exercise.bewegung)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.delete(exercise)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func infoLine(_ label: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack(spacing: 6) {
                Text("\(label):")
                    .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                Text(value)
                    .font(.caption).foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Empty / Overlay

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 56))
                .foregroundStyle(accent.opacity(0.6))
            Text(viewModel.exercises.isEmpty ? "Keine Übungen" : "Keine Treffer")
                .font(.title3).fontWeight(.semibold)
            if viewModel.exercises.isEmpty {
                Button { showAddSheet = true } label: {
                    Label("Übung anlegen", systemImage: "plus.circle.fill")
                        .font(.headline).foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(accent).cornerRadius(12)
                }
            } else {
                Button {
                    viewModel.resetFilters()
                    viewModel.searchText = ""
                } label: {
                    Text("Suche & Filter zurücksetzen")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(accent)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var importOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().tint(.white)
                Text("Video wird verschlüsselt …").font(.subheadline).foregroundStyle(.white)
            }
            .padding(28).background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
