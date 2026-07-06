//
//  KGGWheelPickerRow.swift
//  Agil10.0
//
//  Created by Christiane Roth on 05.07.26.
//


//
//  KGGWheelPickerRow.swift
//  AgilKGG
//
//  Wiederverwendbare Picker-Zeile im Uhrzeit-Stil:
//  Zugeklappt zeigt die Zeile nur die aktuelle Auswahl,
//  Tippen klappt das Wheel auf/zu. Optionales Plus zum Anlegen neuer Werte.
//  Wird im Anlege-Formular und im Library-Filter verwendet.
//

import SwiftUI

struct KGGWheelPickerRow: View {
    let title: String
    let values: [String]
    @Binding var selection: String          // "" = keine Auswahl
    var emptyLabel: String = "Keine Auswahl"
    var accent: Color
    var onAddNew: (() -> Void)? = nil

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            header

            if isExpanded {
                Picker(title, selection: $selection) {
                    Text(emptyLabel).tag("")
                    ForEach(values, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .clipped()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text(title)
                .foregroundStyle(.primary)

            if let onAddNew {
                Button(action: onAddNew) {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(accent)
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            Text(selection.isEmpty ? emptyLabel : selection)
                .foregroundStyle(selection.isEmpty ? .secondary : accent)
                .fontWeight(selection.isEmpty ? .regular : .semibold)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.toggle()
        }
    }
}

#Preview {
    @Previewable @State var selection = ""

    Form {
        Section("Kategorien") {
            KGGWheelPickerRow(
                title: "Gelenk",
                values: ["art. genus", "art. coxae", "columna vertebralis"],
                selection: $selection,
                emptyLabel: "Keine Auswahl",
                accent: .pink,
                onAddNew: {}
            )
        }
    }
}