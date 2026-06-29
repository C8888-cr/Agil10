//
//  KGGExerciseEditorView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 27.06.26.
//


//
//  KGGExerciseEditorView.swift
//  AgilKGG
//
//  Übung editieren: Reps, Sets, Gewicht, Pause, Tempo, ROM mit Steppern
//

import SwiftUI
import SwiftData
import AgilCore

struct KGGExerciseEditorView: View {
    @StateObject private var viewModel: KGGExerciseEditorViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    let exercise: KGGExercise
    let modelContext: ModelContext
    let patientId: UUID
    
    init(exercise: KGGExercise, modelContext: ModelContext, patientId: UUID) {
        self.exercise = exercise
        self.modelContext = modelContext
        self.patientId = patientId
        _viewModel = StateObject(wrappedValue: KGGExerciseEditorViewModel(exercise: exercise, modelContext: modelContext, patientId: patientId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Video Info
                        videoInfoCard
                        
                        // Parameter Editor
                        parametersCard
                        
                        // Änderungsnotiz
                        notesCard
                        
                        // Save Button
                        saveButton
                        
                        if let error = viewModel.errorMessage {
                            errorBanner(error)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Übung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var videoInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.videoTitle)
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sparte")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(exercise.sparte)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Muskelgruppe")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(exercise.muskelgruppe)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Equipment")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(exercise.equipment)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Parameter")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Reps
            parameterRow(
                label: "Wiederholungen",
                icon: "repeat",
                value: $viewModel.editingReps,
                onIncrement: { viewModel.incrementReps() },
                onDecrement: { viewModel.decrementReps() }
            )
            
            Divider()
            
            // Sets
            parameterRow(
                label: "Sätze",
                icon: "square.stack.3d.up",
                value: $viewModel.editingSets,
                onIncrement: { viewModel.incrementSets() },
                onDecrement: { viewModel.decrementSets() }
            )
            
            Divider()
            
            // Weight
            parameterRow(
                label: "Gewicht (kg)",
                icon: "dumbbell",
                value: $viewModel.editingWeight,
                onIncrement: { viewModel.incrementWeight() },
                onDecrement: { viewModel.decrementWeight() }
            )
            
            Divider()
            
            // Pause
            parameterRow(
                label: "Pause (Sek)",
                icon: "pause.circle",
                value: $viewModel.editingPause,
                onIncrement: { viewModel.incrementPause() },
                onDecrement: { viewModel.decrementPause() }
            )
            
            Divider()
            
            // Tempo
            VStack(alignment: .leading, spacing: 8) {
                Label("Tempo", systemImage: "metronome")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                TextField("z.B. 2-0-2", text: $viewModel.editingTempo)
                    .textFieldStyle(.roundedBorder)
                
                Text("eccentric-pause-concentric")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // ROM
            VStack(alignment: .leading, spacing: 8) {
                Label("Bewegungsumfang", systemImage: "arrow.left.and.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                TextField("z.B. Full ROM", text: $viewModel.editingROM)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func parameterRow(
        label: String,
        icon: String,
        value: Binding<String>,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Button(action: onDecrement) {
                    Image(systemName: "minus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(themeManager.currentTheme.accentColor)
                }
                
                TextField("Value", text: value)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.headline)
                
                Button(action: onIncrement) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(themeManager.currentTheme.accentColor)
                }
            }
        }
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Änderungsnotiz (optional)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $viewModel.editingNote)
                .frame(height: 80)
                .textFieldStyle(.roundedBorder)
                .border(Color(.systemGray3))
                .cornerRadius(6)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var saveButton: some View {
        Button {
            do {
                try viewModel.saveChanges()
                dismiss()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        } label: {
            if viewModel.isSaving {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Speichern")
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(viewModel.isValid ? themeManager.currentTheme.accentColor : Color.gray)
        .foregroundStyle(.white)
        .cornerRadius(8)
        .disabled(!viewModel.isValid || viewModel.isSaving)
    }
    
    private func errorBanner(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    Text("Exercise Editor Preview")
}
