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
//  Dauer als Stepper, Geräte-Parameter (Stufe/Sitzhöhe/Speed/Gewicht) optional.
//

import SwiftUI

struct KGGAddWarmupSheet: View {
    let accent: Color
    let onConfirm: (
        _ type: String,
        _ duration: Int,
        _ level: Int?,
        _ seatLevel: Int?,
        _ speedKmh: Double?,
        _ weight: Double?,
        _ notes: String?
    ) -> Void

    @Environment(\.dismiss) private var dismiss

    private static let presetTypes = ["Fahrrad", "Laufband", "Crosstrainer", "Rudergerät", "Stepper"]
    private static let customTag = "Eigenes…"

    @State private var selectedType = "Fahrrad"
    @State private var customType = ""
    @State private var duration = 10

    @State private var levelText = ""
    @State private var seatLevelText = ""
    @State private var speedText = ""
    @State private var weightText = ""
    @State private var notes = ""

    private var resolvedType: String {
        selectedType == Self.customTag
            ? customType.trimmingCharacters(in: .whitespacesAndNewlines)
            : selectedType
    }

    private var isValid: Bool {
        !resolvedType.isEmpty && duration > 0
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
                } header: {
                    Text("Belastung")
                }

                Section {
                    TextField("Stufe (optional)", text: $levelText)
                        .keyboardType(.numberPad)
                    TextField("Sitzhöhe, Stufe (optional)", text: $seatLevelText)
                        .keyboardType(.numberPad)
                    TextField("Speed, km/h (optional)", text: $speedText)
                        .keyboardType(.decimalPad)
                    TextField("Gewicht, kg (optional)", text: $weightText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Geräte-Einstellungen")
                } footer: {
                    Text("Nur ausfüllen, was für dieses Gerät zutrifft. Leere Felder werden später nicht angezeigt.")
                }

                Section("Notiz (optional)") {
                    TextField("z.B. langsam steigern", text: $notes)
                }

                Section {
                    Button {
                        confirm()
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

    private func confirm() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        onConfirm(
            resolvedType,
            duration,
            Int(levelText.trimmingCharacters(in: .whitespacesAndNewlines)),
            Int(seatLevelText.trimmingCharacters(in: .whitespacesAndNewlines)),
            Double(speedText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")),
            Double(weightText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")),
            trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        dismiss()
    }
}

#Preview {
    KGGAddWarmupSheet(accent: .pink) { _, _, _, _, _, _, _ in }
}
