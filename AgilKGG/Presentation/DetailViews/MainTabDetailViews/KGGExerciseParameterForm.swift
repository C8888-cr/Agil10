//
//  KGGExerciseParameterForm.swift
//  AgilKGG
//
//  DAS eine Parameter-Formular der App (Single Source of Truth fürs UI):
//  Video-Thumbnail, Wiederholungen, Sätze, Gewicht, Pause, Tempo (Wheel-Picker),
//  optionale Geräte-Einstellungen (Stufe/Sitzhöhe) und optionale Notizen.
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
    @Binding var level: Int?
    @Binding var seatLevel: Int?
    @Binding var notes: String?
    
    @State private var isTempoExpanded = false

    let onConfirm: () -> Void

    private var isValid: Bool {
        reps > 0 && sets > 0 && weight >= 0 && pause >= 0 &&
        !tempo.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Tempo-Wheel-Bindings (konzentrisch - halten - exzentrisch)

    private func tempoParts() -> [Int] {
        let parts = tempo.split(separator: "-").compactMap { Int($0) }
        return parts.count == 3 ? parts : [2, 0, 2]
    }

    private func tempoComponent(_ index: Int) -> Binding<Int> {
        Binding(
            get: { tempoParts()[index] },
            set: { newValue in
                var parts = tempoParts()
                parts[index] = min(max(newValue, 0), 9)
                tempo = parts.map(String.init).joined(separator: "-")
            }
        )
    }

    // MARK: - Optionale Int-Felder als String-Bindings

    private func optionalIntBinding(_ value: Binding<Int?>) -> Binding<String> {
        Binding(
            get: { value.wrappedValue.map(String.init) ?? "" },
            set: { value.wrappedValue = Int($0.trimmingCharacters(in: .whitespaces)) }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { notes ?? "" },
            set: { notes = $0.isEmpty ? nil : $0 }
        )
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
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isTempoExpanded.toggle()
                        }
                    } label: {
                        Text(tempo)
                            .foregroundStyle(.primary)
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                            .frame(width: 94, height: 32)
                            .background(Capsule().fill(Color(.systemGray5)))
                    }
                    .buttonStyle(.plain)
                }
                    
                if isTempoExpanded {
                    HStack(spacing: 0) {
                        tempoWheel(label: "konz.", binding: tempoComponent(0))
                        Text("-").foregroundStyle(.secondary)
                        tempoWheel(label: "halten", binding: tempoComponent(1))
                        Text("-").foregroundStyle(.secondary)
                        tempoWheel(label: "exz.", binding: tempoComponent(2))
                    }
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } header: {
                Text("Parameter")
            } footer: {
                if isTempoExpanded {
                    Text("Konzentrisch – halten – exzentrisch, jeweils in Sekunden (0–9). Zum Schließen erneut auf Tempo tippen.")
                }
            }

            Section {
                TextField("Stufe (optional)", text: optionalIntBinding($level))
                    .keyboardType(.numberPad)
                TextField("Sitzhöhe, Stufe (optional)", text: optionalIntBinding($seatLevel))
                    .keyboardType(.numberPad)
            } header: {
                Text("Geräte-Einstellungen")
            } footer: {
                Text("Nur ausfüllen, was für dieses Gerät zutrifft.")
            }

            Section("Notizen (optional)") {
                TextField("z.B. besonders langsam ausführen", text: notesBinding, axis: .vertical)
                    .lineLimit(2...4)
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

    private func tempoWheel(label: String, binding: Binding<Int>) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Picker(label, selection: binding) {
                ForEach(0...9, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 70, height: 100)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var reps = 10
    @Previewable @State var sets = 3
    @Previewable @State var weight = 12.5
    @Previewable @State var pause = 60
    @Previewable @State var tempo = "2-0-2"
    @Previewable @State var level: Int? = nil
    @Previewable @State var seatLevel: Int? = nil
    @Previewable @State var notes: String? = nil

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
            level: $level,
            seatLevel: $seatLevel,
            notes: $notes,
            onConfirm: {}
        )
        .navigationTitle("Parameter")
        .navigationBarTitleDisplayMode(.inline)
    }
}
