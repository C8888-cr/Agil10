//
//  ExerciseConfigView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 27.06.26.
//


//
//  ExerciseConfigView.swift
//  AgilKGG
//
//  Bearbeitet Reps/Gewichte der zugeordneten Übungen.
//  Therapeut kann Pro-Patient-Pro-Video anpassen.
//

import SwiftUI
import AgilCore
import SwiftData

struct ExerciseConfigView: View {
    @EnvironmentObject var viewModel: KGGTherapistViewModel
    
    @State private var editingId: UUID?
    @State private var editingReps: String = ""
    @State private var editingWeight: String = ""
    @State private var errorAlert: AlertError?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header
                    if let patient = viewModel.selectedPatient {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Übungen für \(patient.patientNumber)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(patient.currentAssignments.count) Übung(en) zugewiesen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    
                    // Übungs-Liste
                    if let patient = viewModel.selectedPatient, !patient.currentAssignments.isEmpty {
                        exerciseList(for: patient)
                    } else {
                        noExercisesState
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Fehler", isPresented: .constant(errorAlert != nil), presenting: errorAlert) { error in
            Button("OK") { errorAlert = nil }
        } message: { error in
            Text(error.message)
        }
    }
    
    // MARK: - Subviews
    
    private var noExercisesState: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            VStack(spacing: 8) {
                Text("Keine Übungen zugewiesen")
                    .font(.headline)
                
                Text("Gehen Sie zum Video-Tab und wählen Sie Übungen aus")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func exerciseList(for patient: KGGPatient) -> some View {
        List {
            ForEach(patient.currentAssignments) { assignment in
                exerciseRow(assignment, patient: patient)
            }
        }
        .listStyle(.plain)
        .background(Color.white)
        .cornerRadius(12)
        .scrollContentBackground(.hidden)
    }
    
    private func exerciseRow(_ assignment: ExerciseAssignment, patient: KGGPatient) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Video-Name
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getVideoTitle(assignment.exerciseId))
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("Video ID: \(assignment.exerciseId.uuidString.prefix(8))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
                
                Spacer()
                
                Button {
                    removeExercise(assignment.exerciseId, from: patient)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
            
            // Parameter-Editor
            if editingId == assignment.exerciseId {
                editingView(for: assignment, patient: patient)
            } else {
                viewModeView(for: assignment, patient: patient)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func viewModeView(for assignment: ExerciseAssignment, patient: KGGPatient) -> some View {
        HStack(spacing: 12) {
            // Reps-Anzeige
            VStack(alignment: .center, spacing: 4) {
                Text("Wiederholungen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(assignment.reps)x")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(8)
            
            // Gewicht-Anzeige
            VStack(alignment: .center, spacing: 4) {
                Text("Gewicht")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(Int(assignment.weight)) kg")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(8)
            
            // Edit-Button
            Button {
                startEditing(assignment)
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
    
    private func editingView(for assignment: ExerciseAssignment, patient: KGGPatient) -> some View {
        VStack(spacing: 12) {
            // Reps-Input
            VStack(alignment: .leading, spacing: 4) {
                Label("Wiederholungen", systemImage: "repeat")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Button {
                        decrementReps()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    TextField("Wdh", text: $editingReps)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.headline)
                    
                    Button {
                        incrementReps()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            
            // Gewicht-Input
            VStack(alignment: .leading, spacing: 4) {
                Label("Gewicht (kg)", systemImage: "dumbbell")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Button {
                        decrementWeight()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    TextField("Gewicht", text: $editingWeight)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.headline)
                    
                    Button {
                        incrementWeight()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            
            // Save/Cancel Buttons
            HStack(spacing: 12) {
                Button("Abbrechen") {
                    editingId = nil
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(8)
                
                Button {
                    saveChanges(for: assignment, patient: patient)
                } label: {
                    Text("Speichern")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
    
    // MARK: - Actions
    
    private func startEditing(_ assignment: ExerciseAssignment) {
        editingId = assignment.exerciseId
        editingReps = "\(assignment.reps)"
        editingWeight = String(format: "%.1f", assignment.weight)
    }
    
    private func saveChanges(for assignment: ExerciseAssignment, patient: KGGPatient) {
        guard let reps = Int(editingReps.trimmingCharacters(in: .whitespaces)), reps > 0 else {
            errorAlert = AlertError(message: "Wiederholungen müssen > 0 sein")
            return
        }
        
        guard let weight = Double(editingWeight.trimmingCharacters(in: .whitespaces)), weight >= 0 else {
            errorAlert = AlertError(message: "Gewicht darf nicht negativ sein")
            return
        }
        
        do {
            try viewModel.updateExerciseParams(
                for: patient,
                videoId: assignment.exerciseId,
                newReps: reps,
                newWeight: weight
            )
            editingId = nil
        } catch {
            errorAlert = AlertError(message: error.localizedDescription)
        }
    }
    
    private func removeExercise(_ videoId: UUID, from patient: KGGPatient) {
        do {
            try viewModel.removeExercise(from: patient, videoId: videoId)
        } catch {
            errorAlert = AlertError(message: error.localizedDescription)
        }
    }
    
    private func getVideoTitle(_ videoId: UUID) -> String {
        viewModel.availableVideos.first(where: { $0.videoId == videoId })?.title ?? "Unbekanntes Video"
    }
    
    private func incrementReps() {
        if let reps = Int(editingReps) {
            editingReps = "\(reps + 1)"
        }
    }
    
    private func decrementReps() {
        if let reps = Int(editingReps), reps > 1 {
            editingReps = "\(reps - 1)"
        }
    }
    
    private func incrementWeight() {
        if let weight = Double(editingWeight) {
            editingWeight = String(format: "%.1f", weight + 2.5)
        }
    }
    
    private func decrementWeight() {
        if let weight = Double(editingWeight), weight >= 2.5 {
            editingWeight = String(format: "%.1f", weight - 2.5)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KGGPatient.self, configurations: config)
    let viewModel = KGGTherapistViewModel(modelContext: container.mainContext)
    
    ExerciseConfigView()
        .environmentObject(viewModel)
        .environment(\.modelContext, container.mainContext)
}
