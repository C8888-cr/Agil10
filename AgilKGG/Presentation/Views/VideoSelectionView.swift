//
//  VideoSelectionView.swift
//  AgilKGG
//
//  Lädt KGG-Videos aus der lokalen Bibliothek (Documents/agil-kgg-videos/).
//  Therapeut wählt Videos aus und ordnet sie dem Patienten zu.
//  Video-Parameter (Reps/Gewichte) werden in ExerciseConfigView bearbeitet.
//

import SwiftUI
import SwiftData
import AgilCore

struct VideoSelectionView: View {
    @EnvironmentObject var viewModel: KGGTherapistViewModel
    
    @State private var selectedVideos: Set<UUID> = []
    @State private var showingVideoPreview: KGGVideoInfo?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header
                    if let patient = viewModel.selectedPatient {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Videos für \(patient.patientNumber)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(viewModel.availableVideos.count) verfügbar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    
                    // Video-Liste
                    if viewModel.availableVideos.isEmpty {
                        noVideosState
                    } else {
                        videoList
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Subviews
    
    private var noVideosState: some View {
        VStack(spacing: 24) {
            Image(systemName: "film.fill")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            VStack(spacing: 8) {
                Text("Keine Videos gefunden")
                    .font(.headline)
                
                Text("Speichern Sie .agkv Dateien in Documents/agil-kgg-videos/")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                openDocumentsFolder()
            } label: {
                Label("Ordner öffnen", systemImage: "folder")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var videoList: some View {
        List {
            ForEach(viewModel.availableVideos) { video in
                videoRow(video)
                    .onTapGesture {
                        showingVideoPreview = video
                    }
            }
        }
        .listStyle(.plain)
        .background(Color.white)
        .cornerRadius(12)
        .scrollContentBackground(.hidden)
        .sheet(item: $showingVideoPreview) { video in
            videoPreviewSheet(video)
        }
    }
    
    private func videoRow(_ video: KGGVideoInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("Verschlüsseltes Video")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isVideoAssigned(video.videoId) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.gray)
                }
            }
            
            // Quick-Stats
            HStack(spacing: 12) {
                if let assignment = viewModel.selectedPatient?.currentAssignments.first(where: { $0.exerciseId == video.videoId }) {
                    VStack(spacing: 2) {
                        Text("Wdh")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(assignment.reps)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(6)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
                    
                    VStack(spacing: 2) {
                        Text("Gew")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(assignment.weight)) kg")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(6)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func videoPreviewSheet(_ video: KGGVideoInfo) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(video.title)
                        .font(.headline)
                    
                    Label {
                        Text("Verschlüsselt gespeichert")
                            .font(.caption)
                    } icon: {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.green)
                    }
                    
                    if let assignment = viewModel.selectedPatient?.currentAssignments.first(where: { $0.exerciseId == video.videoId }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aktuelle Einstellung")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Wiederholungen")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(assignment.reps)x")
                                        .font(.headline)
                                }
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Gewicht")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(Int(assignment.weight)) kg")
                                        .font(.headline)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Schließen") {
                        showingVideoPreview = nil
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    
                    Button {
                        toggleVideoAssignment(video)
                        showingVideoPreview = nil
                    } label: {
                        Text(isVideoAssigned(video.videoId) ? "Entfernen" : "Hinzufügen")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isVideoAssigned(video.videoId) ? Color.red : Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Video-Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Actions
    
    private func toggleVideoAssignment(_ video: KGGVideoInfo) {
        guard let patient = viewModel.selectedPatient else { return }
        
        if isVideoAssigned(video.videoId) {
            do {
                try viewModel.removeExercise(from: patient, videoId: video.videoId)
            } catch {
                print("Fehler beim Entfernen: \(error)")
            }
        } else {
            // Neue Übung mit Default-Werten hinzufügen
            do {
                try viewModel.assignExercise(
                    to: patient,
                    videoId: video.videoId,
                    reps: 10,
                    weight: 0.0,
                    videoKey: Data()  // Placeholder – später aus Keychain
                )
            } catch {
                print("Fehler beim Hinzufügen: \(error)")
            }
        }
    }
    
    private func isVideoAssigned(_ videoId: UUID) -> Bool {
        viewModel.selectedPatient?.currentAssignments.contains(where: { $0.exerciseId == videoId }) ?? false
    }
    
    private func openDocumentsFolder() {
        // iPad: Files-App öffnen (über Document Picker)
        // Placeholder – später implementieren wenn nötig
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KGGPatient.self, configurations: config)
    let viewModel = KGGTherapistViewModel(modelContext: container.mainContext)
    
    VideoSelectionView()
        .environmentObject(viewModel)
        .environment(\.modelContext, container.mainContext)
}
