
import SwiftUI
import SwiftData
import AgilCore

struct FilterSheet: View {
    
    
    @ObservedObject var viewModel: VideoLibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            Form {
                // Kategorie
                Section("Übungsart") {
                    Picker("Kategorie", selection: $viewModel.selectedCategory) {
                        Text("Alle").tag(nil as ExerciseCategory?)
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category as ExerciseCategory?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // Körperregion
                Section("Körperregion") {
                    Picker("Region", selection: $viewModel.selectedBodyRegion) {
                        Text("Alle").tag(nil as BodyRegion?)
                        ForEach(BodyRegion.allCases, id: \.self) { region in
                            Label(region.rawValue, systemImage: region.icon)
                                .tag(region as BodyRegion?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // Equipment
                Section("Equipment") {
                    Picker("Equipment", selection: $viewModel.selectedEquipment) {
                        Text("Alle").tag(nil as Equipment?)
                        ForEach(Equipment.allCases, id: \.self) { equipment in
                            Label(equipment.rawValue, systemImage: equipment.icon)
                                .tag(equipment as Equipment?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // Favoriten
                Section {
                    Toggle(isOn: $viewModel.showFavoritesOnly) {
                        Label("Nur Favoriten", systemImage: "star.fill")
                            .tint(themeManager.currentTheme.accentColor)
                    }
                }
                
                // Reset
                Section {
                    Button("Alle Filter zurücksetzen", role: .destructive) {
                        viewModel.clearFilters()
                        dismiss()
                    }
                    .disabled(!viewModel.hasActiveFilters)
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Anwenden") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
