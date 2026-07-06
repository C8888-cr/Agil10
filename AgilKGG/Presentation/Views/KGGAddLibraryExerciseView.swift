//
//  KGGAddLibraryExerciseView.swift
//  AgilKGG
//
//  Formular zum Anlegen einer Übung im Stil des Patientenapp-Upload-Sheets:
//  Form mit Sections, Wheel-Picker-Zeilen für Kategorien (aufklappbar),
//  neue Werte per Plus direkt anlegbar. Video wird verschlüsselt abgelegt.
//

import SwiftUI
import SwiftData
import PhotosUI
import AVKit
import UniformTypeIdentifiers
import AgilCore

struct KGGAddLibraryExerciseView: View {
    @ObservedObject var viewModel: KGGLibraryViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""

    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var selectedVideoURL: URL?
    @State private var selectedVideoName: String = ""
    @State private var isLoadingVideo = false

    // Auswahl pro Kategorie ("" = keine Angabe)
    @State private var selectedMuscle = ""
    @State private var selectedJoint = ""
    @State private var selectedDevice = ""
    @State private var selectedDirection = ""

    // Neuer-Wert-Dialog
    @State private var showAddValueAlert = false
    @State private var addValueCategory: KGGCategoryType?
    @State private var newValueText = ""

    private var accent: Color { themeManager.currentTheme.accentColor }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedVideoURL != nil &&
        !isLoadingVideo &&
        !viewModel.isImporting
    }

    var body: some View {
        NavigationStack {
            Form {
                videoSection
                titleSection
                categoriesSection
                saveSection
            }
            .navigationTitle("Übung anlegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .disabled(viewModel.isImporting)
                }
            }
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert(addValueAlertTitle, isPresented: $showAddValueAlert) {
                TextField("Neuen Wert eingeben", text: $newValueText)
                Button("Hinzufügen") { confirmAddValue() }
                Button("Abbrechen", role: .cancel) { cancelAddValue() }
            } message: {
                Text("Wird für diese Praxis gespeichert und ist sofort überall auswählbar.")
            }
        }
        .onChange(of: selectedVideoItem) { _, newValue in
            guard let newValue else { return }
            Task { await loadVideo(from: newValue) }
        }
    }

    // MARK: - Sections

    private var videoSection: some View {
        Section("Video") {
            PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundStyle(accent)
                    Text(selectedVideoURL == nil ? "Video aus Mediathek wählen" : "Video ersetzen")
                    Spacer()
                    if isLoadingVideo {
                        ProgressView()
                    }
                }
            }

            if let url = selectedVideoURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text(selectedVideoName.isEmpty ? url.lastPathComponent : selectedVideoName)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
    }

    private var titleSection: some View {
        Section {
            TextField("z.B. Kniebeuge am Seilzug", text: $title)
        } header: {
            Text("Name")
        } footer: {
            Text("Der Name muss eindeutig und verständlich sein.")
        }
    }

    private var categoriesSection: some View {
        Section {
            ForEach(KGGCategoryType.allCases) { category in
                KGGWheelPickerRow(
                    title: category.rawValue,
                    values: viewModel.categoryValues(category),
                    selection: selectionBinding(for: category),
                    emptyLabel: "Keine Angabe",
                    accent: accent,
                    onAddNew: { startAddValue(category: category) }
                )
            }
        } header: {
            Text("Kategorien")
        } footer: {
            Text("Über das Plus kannst du eigene Werte für deine Praxis ergänzen.")
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                save()
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isImporting {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                    }
                    Text("Übung speichern")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!canSave)
            .tint(accent)
        } footer: {
            if viewModel.isImporting {
                Text("Video wird verschlüsselt …")
            }
        }
    }

    // MARK: - Bindings

    private func selectionBinding(for category: KGGCategoryType) -> Binding<String> {
        switch category {
        case .muskel: return $selectedMuscle
        case .gelenk: return $selectedJoint
        case .geraet: return $selectedDevice
        case .bewegungsrichtung: return $selectedDirection
        }
    }

    // MARK: - Neuer Wert (Alert mit Textfeld)

    private var addValueAlertTitle: String {
        guard let cat = addValueCategory else { return "Neuer Wert" }
        return "Neuer Wert: \(cat.rawValue)"
    }

    private func startAddValue(category: KGGCategoryType) {
        addValueCategory = category
        newValueText = ""
        showAddValueAlert = true
    }

    private func confirmAddValue() {
        guard let category = addValueCategory else { return }
        let trimmed = newValueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { cancelAddValue(); return }

        viewModel.addCategoryValue(category, value: trimmed)

        // Neuen Wert direkt als Auswahl übernehmen
        selectionBinding(for: category).wrappedValue = trimmed
        cancelAddValue()
    }

    private func cancelAddValue() {
        newValueText = ""
        addValueCategory = nil
    }

    // MARK: - Speichern

    private func save() {
        guard let videoURL = selectedVideoURL else { return }

        let ex = viewModel.create(
            title: title,
            muskel: selectedMuscle.nilIfEmpty,
            gelenk: selectedJoint.nilIfEmpty,
            geraet: selectedDevice.nilIfEmpty,
            bewegung: selectedDirection.nilIfEmpty,
            notes: nil
        )

        guard let ex else { return }

        Task {
            
            await viewModel.attachVideo(videoURL, to: ex)

                if viewModel.errorMessage == nil {
                    dismiss()
                }
            }
    }

    private func loadVideo(from item: PhotosPickerItem) async {
        await MainActor.run {
            isLoadingVideo = true
        }
        defer {
            Task { @MainActor in
                isLoadingVideo = false
            }
        }

        do {
            if let video = try await item.loadTransferable(type: VideoFile.self) {
                await MainActor.run {
                    selectedVideoURL = video.url
                    selectedVideoName = video.url.lastPathComponent
                }
            } else {
                await MainActor.run {
                    viewModel.errorMessage = "Video konnte nicht geladen werden"
                }
            }
        } catch {
            await MainActor.run {
                viewModel.errorMessage = "Video konnte nicht geladen werden: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Helpers

private extension String {
    /// Leerer String → nil (für optionale Kategorie-Felder).
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

struct VideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")

            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }

            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return VideoFile(url: tempURL)
        }
    }
}
