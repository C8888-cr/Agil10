//
//  KGGLibraryFilterView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.07.26.
//


//
//  KGGLibraryFilterView.swift
//  AgilKGG
//
//  Wiederverwendbarer Filterbereich für die Übungsbibliothek:
//  Header mit Badge + Zurücksetzen, aufklappbar, darin Wheel-Picker-Zeilen
//  pro Kategorie inkl. Anlegen neuer Werte.
//  Verwendet in KGGLibraryView und KGGAssignExerciseSheet.
//

import SwiftUI
import AgilCore

struct KGGLibraryFilterView: View {
    @ObservedObject var viewModel: KGGLibraryViewModel
    let accent: Color

    @State private var filtersExpanded = false

    // Neuer-Wert-Dialog
    @State private var showAddValueAlert = false
    @State private var addValueCategory: KGGCategoryType?
    @State private var newValueText = ""

    var body: some View {
        VStack(spacing: 0) {
            filterHeader

            if filtersExpanded {
                VStack(spacing: 0) {
                    ForEach(KGGCategoryType.allCases) { cat in
                        KGGWheelPickerRow(
                            title: cat.rawValue,
                            values: viewModel.categoryValues(cat),
                            selection: filterBinding(cat),
                            emptyLabel: "Alle",
                            accent: accent,
                            onAddNew: { startAddValue(category: cat) }
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                        if cat != KGGCategoryType.allCases.last {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .animation(.easeInOut(duration: 0.2), value: filtersExpanded)
        .alert(addValueAlertTitle, isPresented: $showAddValueAlert) {
            TextField("Neuen Wert eingeben", text: $newValueText)
            Button("Hinzufügen") { confirmAddValue() }
            Button("Abbrechen", role: .cancel) { cancelAddValue() }
        } message: {
            Text("Wird für diese Praxis gespeichert und ist sofort überall auswählbar.")
        }
    }

    // MARK: - Header

    private var filterHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.activeFilterCount > 0
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
                .foregroundStyle(viewModel.activeFilterCount > 0 ? accent : .secondary)

            Text("Filter")
                .font(.subheadline)
                .fontWeight(.semibold)

            if viewModel.activeFilterCount > 0 {
                Text("\(viewModel.activeFilterCount)")
                    .font(.caption2).fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(accent)
                    .clipShape(Capsule())
            }

            Spacer()

            if viewModel.activeFilterCount > 0 {
                Button("Zurücksetzen") {
                    viewModel.resetFilters()
                }
                .font(.caption)
                .foregroundStyle(accent)
            }

            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(filtersExpanded ? 180 : 0))
        }
        .padding(12)
        .contentShape(Rectangle())
        .onTapGesture {
            filtersExpanded.toggle()
        }
    }

    // MARK: - Bindings

    /// Bindet die Wheel-Auswahl direkt an den Filter im ViewModel ("" = Alle).
    private func filterBinding(_ category: KGGCategoryType) -> Binding<String> {
        Binding(
            get: { viewModel.activeFilters[category] ?? "" },
            set: { viewModel.setFilter(category, value: $0) }
        )
    }

    // MARK: - Neuer Wert

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
        viewModel.setFilter(category, value: trimmed)   // direkt als Filter übernehmen
        cancelAddValue()
    }

    private func cancelAddValue() {
        newValueText = ""
        addValueCategory = nil
    }
}