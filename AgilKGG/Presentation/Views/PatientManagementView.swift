//
//  PatientManagementView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 27.06.26.
//


//
//  PatientManagementView.swift
//  AgilKGG
//
//  Verwaltet Patienten: neue Nummer eingeben, bestehende wählen, löschen.
//  Daten kommen aus TheOrg – hier nur lokale Verwaltung in der Therapeuten-App.
//

import SwiftUI
import AgilCore
import SwiftData

struct PatientManagementView: View {
    @EnvironmentObject var viewModel: KGGTherapistViewModel
    
    @State private var newPatientNumber = ""
    @State private var showAddingSheet = false
    @State private var errorAlert: AlertError?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Patienten-Verwaltung")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Geben Sie die Patientennummer ein (z.B. Pat1, Pat2)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Patienten-Liste
                    if viewModel.patients.isEmpty {
                        emptyState
                    } else {
                        patientList
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddingSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddingSheet) {
            addPatientSheet
        }
        .alert("Fehler", isPresented: .constant(errorAlert != nil), presenting: errorAlert) { error in
            Button("OK") { errorAlert = nil }
        } message: { error in
            Text(error.message)
        }
    }
    
    // MARK: - Subviews
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            VStack(spacing: 8) {
                Text("Keine Patienten hinzugefügt")
                    .font(.headline)
                
                Text("Fügen Sie einen Patienten hinzu, um Übungen zuzuweisen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showAddingSheet = true
            } label: {
                Label("Patient hinzufügen", systemImage: "plus.circle")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var patientList: some View {
        List(selection: $viewModel.selectedPatient) {
            ForEach(viewModel.patients) { patient in
                patientRow(patient)
                    .tag(patient)
            }
            .onDelete { offsets in
                deletePatients(at: offsets)
            }
        }
        .listStyle(.plain)
        .background(Color.white)
        .cornerRadius(12)
        .scrollContentBackground(.hidden)
    }
    
    private func patientRow(_ patient: KGGPatient) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.patientNumber)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(patient.currentAssignments.count) Übungen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if viewModel.selectedPatient?.patientNumber == patient.patientNumber {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            if !patient.currentAssignments.isEmpty {
                HStack(spacing: 12) {
                    ForEach(patient.currentAssignments.prefix(3)) { assignment in
                        VStack(spacing: 2) {
                            Text("\(assignment.reps)x")
                                .font(.caption2)
                                .fontWeight(.bold)
                            
                            Text("\(Int(assignment.weight)) kg")
                                .font(.caption2)
                        }
                        .padding(6)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                    }
                    
                    if patient.currentAssignments.count > 3 {
                        Text("+\(patient.currentAssignments.count - 3)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var addPatientSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Neue Patientennummer")
                        .font(.headline)
                    
                    Text("Geben Sie die Nummer aus TheOrg ein (z.B. Pat1, Pat2, Pat42)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                TextField("z.B. Pat1", text: $newPatientNumber)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Abbrechen") {
                        newPatientNumber = ""
                        showAddingSheet = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    
                    Button {
                        addNewPatient()
                    } label: {
                        Text("Hinzufügen")
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
            .navigationTitle("Patient hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Actions
    
    private func addNewPatient() {
        do {
            try viewModel.addPatient(number: newPatientNumber)
            newPatientNumber = ""
            showAddingSheet = false
        } catch {
            errorAlert = AlertError(message: error.localizedDescription)
        }
    }
    
    private func deletePatients(at offsets: IndexSet) {
        for index in offsets {
            do {
                try viewModel.deletePatient(viewModel.patients[index])
            } catch {
                errorAlert = AlertError(message: error.localizedDescription)
            }
        }
    }
}

// MARK: - Helper Types

struct AlertError: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KGGPatient.self, configurations: config)
    let viewModel = KGGTherapistViewModel(modelContext: container.mainContext)
    
    PatientManagementView()
        .environmentObject(viewModel)
        .environment(\.modelContext, container.mainContext)
}
