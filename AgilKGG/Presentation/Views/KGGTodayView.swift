//
//  KGGTodayView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 29.06.26.
//

import SwiftUI
import AgilCore
import SwiftData

struct KGGTodayView: View {
    @StateObject private var viewModel: KGGTodayViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showPatientSelector = false
    
    init(modelContext: ModelContext, praxisId: UUID) {
        _viewModel = StateObject(wrappedValue:
            KGGTodayViewModel(modelContext: modelContext, praxisId: praxisId)
        )
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if viewModel.selectedPatients.isEmpty {
                EmptyStateView(onAddTapped: { showPatientSelector = true })
            } else {
                todayPatientsList
            }
        }
        .navigationTitle("KGG heute")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                            Button {
                                if viewModel.canOpenPatientSelector() {
                                    showPatientSelector = true
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(themeManager.currentTheme.accentColor)
                            }
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            if !viewModel.selectedPatients.isEmpty {
                                Button(role: .destructive) {
                                    viewModel.clearToday()
                                } label: {
                                    Image(systemName: "trash.fill")
                                }
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            KGGLogoMenu()
                        }
                    }
                    .sheet(isPresented: $showPatientSelector) {
                        patientSelectorSheet
                            .onAppear {
                                print("DEBUG: Sheet geöffnet. Gefilterte Patienten: \(viewModel.filteredPatients.count)")  // ← Debug
                            }
                    }
                    .alert("Hinweis", isPresented: Binding(
                        get: { viewModel.errorMessage != nil },
                        set: { newValue in if !newValue { viewModel.errorMessage = nil } }
                    )) {
                        Button("OK") { viewModel.errorMessage = nil }
                    } message: {
                        Text(viewModel.errorMessage ?? "")
                    }
        
        .onAppear {
            print("DEBUG KGGTodayView.onAppear - viewModel.allPatients: \(viewModel.allPatients.count)")
            viewModel.loadPatients()
        }
    }
    
    private var todayPatientsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.selectedPatients) { patient in
                    NavigationLink {
                        KGGPatientDetailView(patient: patient, modelContext: modelContext)
                            .environmentObject(themeManager)
                    } label: {
                        // Reuse: PatientCard mit zusätzlichem Remove-Button
                        PatientCard(
                            patient: patient,
                            onDelete: { viewModel.removeFromToday(patient) }
                        )
                        .environmentObject(themeManager)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }
    
    private var patientSelectorSheet: some View {
        NavigationStack {
            print("DEBUG patientSelectorSheet: filteredPatients.count = \(viewModel.filteredPatients.count)")
            print("DEBUG patientSelectorSheet: allPatients.count = \(viewModel.allPatients.count)")
            
            return List {
                if viewModel.filteredPatients.isEmpty {
                    Text("Keine Patienten verfügbar")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.filteredPatients) { patient in
                        if !viewModel.selectedPatients.contains(where: { $0.id == patient.id }) {
                            Button {
                                print("DEBUG: Patient \(patient.patientNumber) hinzugefügt")
                                viewModel.addToToday(patient)
                                showPatientSelector = false
                            } label: {
                                PatientCard(patient: patient, onDelete: {})
                                    .environmentObject(themeManager)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Suchen..."
            )
            .onChange(of: viewModel.searchText) {
                viewModel.applySearch()
            }
            .navigationTitle("Patient hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
