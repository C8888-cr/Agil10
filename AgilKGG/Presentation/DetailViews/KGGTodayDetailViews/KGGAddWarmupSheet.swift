//
//  KGGAddWarmupSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.07.26.
//


//
//  KGGAddWarmupSheet.swift
//  AgilKGG
//
//  Warmup anlegen: fester Typ-Katalog (Wheel) + eigener Typ,
//  Dauer als Stepper, Intensität als Freitext.
//

import SwiftUI

struct KGGAddWarmupSheet: View {
    let accent: Color
    let onConfirm: (_ type: String, _ duration: Int, _ intensity: String, _ notes: String?) -> Void

    @Environment(\.dismiss) private var dismiss

    private static let presetTypes = ["Fahrrad", "Laufband", "Crosstrainer", "Rudergerät", "Stepper"]
    private static let customTag = "Eigenes…"

    @State private var selectedType = "Fahrrad"
    @State private var customType = ""
    @State private var duration = 10
    @State private var intensity = ""
    @State private var notes = ""

    private var resolvedType: String {
        selectedType == Self.customTag
            ? customType.trimmingCharacters(in: .whitespacesAndNewlines)
            : selectedType
    }

    private var isValid: Bool {
        !resolvedType.isEmpty && duration > 0 &&
        !intensity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Gerät") {
                    Picker("Typ", selection: $selectedType) {
                        ForEach(Self.presetTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                        Text(Self.customTag).tag(Self.customTag)
                    }
                    .pickerStyle(.menu)

                    if selectedType == Self.customTag {
                        TextField("z.B. Seilspringen", text: $customType)
                    }
                }

                Section {
                    Stepper("Dauer: \(duration) Min", value: $duration, in: 1...60)
                    TextField("Intensität, z.B. Widerstand Level 3", text: $intensity)
                } header: {
                    Text("Belastung")
                }

                Section("Notiz (optional)") {
                    TextField("z.B. langsam steigern", text: $notes)
                }

                Section {
                    Button {
                        let note = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        onConfirm(resolvedType, duration, intensity.trimmingCharacters(in: .whitespacesAndNewlines), note.isEmpty ? nil : note)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "flame.fill")
                            Text("Warmup hinzufügen")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .tint(accent)
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Warmup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    KGGAddWarmupSheet(accent: .pink) { _, _, _, _ in }
}