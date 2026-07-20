//
//  KGGExerciseParameterForm.swift
//  AgilKGG
//
//  DAS eine Parameter-Formular der App (Single Source of Truth fürs UI):
//  Video-Thumbnail, Wiederholungen, Sätze, Gewicht, Pause, Tempo.
//  Wird fullscreen verwendet beim Zuweisen (KGGAssignExerciseSheet)
//  und beim Bearbeiten (KGGExerciseEditorView).
//

import SwiftUI

struct KGGExerciseParameterForm: View {
    let exerciseTitle: String
    let thumbnailData: Data?
    let confirmLabel: String
    let accent: Color

    @Binding var reps: Int
    @Binding var sets: Int
    @Binding var weight: Double
    @Binding var pause: Int
    @Binding var tempo: String

    let onConfirm: () -> Void

    private var isValid: Bool {
        reps > 0 && sets > 0 && weight >= 0 && pause >= 0 &&
        !tempo.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    if let data = thumbnailData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray5))
                                .frame(width: 64, height: 64)
                            Image(systemName: "video.slash")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(exerciseTitle)
                        .font(.headline)
                }
            }

            Section {
                Stepper("Wiederholungen: \(reps)", value: $reps, in: 1...100)
                Stepper("Sätze: \(sets)", value: $sets, in: 1...20)
                Stepper("Gewicht: \(weight.formatted()) kg", value: $weight, in: 0...500, step: 0.5)
                Stepper("Pause: \(pause) s", value: $pause, in: 0...600, step: 15)

                HStack {
                    Text("Tempo")
                    Spacer()
                    TextField("z.B. 2-0-2", text: $tempo)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                }
            } header: {
                Text("Parameter")
            } footer: {
                Text("Tempo: exzentrisch – Pause – konzentrisch (z.B. 2-0-2). Steuert die Pillen-Animation in der Patienten-App.")
            }

            Section {
                Button(action: onConfirm) {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                        Text(confirmLabel)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .tint(accent)
                .disabled(!isValid)
            }
        }
    }
}

#Preview {
    @Previewable @State var reps = 10
    @Previewable @State var sets = 3
    @Previewable @State var weight = 12.5
    @Previewable @State var pause = 60
    @Previewable @State var tempo = "2-0-2"

    NavigationStack {
        KGGExerciseParameterForm(
            exerciseTitle: "Kniebeuge am Seilzug",
            thumbnailData: nil,
            confirmLabel: "Übung zuweisen",
            accent: .pink,
            reps: $reps,
            sets: $sets,
            weight: $weight,
            pause: $pause,
            tempo: $tempo,
            onConfirm: {}
        )
        .navigationTitle("Parameter")
        .navigationBarTitleDisplayMode(.inline)
    }
}
