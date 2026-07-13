//
//  AddPatientSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 29.06.26.
//

import SwiftUI
import AgilCore
import SwiftData

// MARK: - Add Sheet

struct AddPatientSheet: View {
    
    @StateObject var viewModel: KGGPatientListViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showAddSheet = false
    @State private var newPatientNumber = ""
    @State private var errorAlert: AlertError?
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Neue Patientennummer")
                        .font(.headline)
                    Text("z.B. Pat1, Pat2, Pat42")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("Patientennummer", text: $newPatientNumber)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        newPatientNumber = ""
                        showAddSheet = false
                    } label: {
                        Text("Abbrechen")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }
                    .foregroundStyle(.primary)
                    
                    Button {
                        addPatient()
                    } label: {
                        Text("Hinzufügen")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(newPatientNumber.isEmpty ? Color(.systemGray3) : themeManager.currentTheme.accentColor)
                            .cornerRadius(12)
                    }
                    .foregroundStyle(.white)
                    .disabled(newPatientNumber.isEmpty)
                }
            }
            .padding(20)
            .navigationTitle("Patient hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
        }
                .alert("Fehler", isPresented: .constant(errorAlert != nil), presenting: errorAlert) { _ in
                    Button("OK") { errorAlert = nil }
                } message: { error in
                    Text(error.message)
                }
                .presentationDetents([.height(280)])
            }
    
    // MARK: - Actions
    
    private func addPatient() {
        do {
            try viewModel.addPatient(number: newPatientNumber)
            newPatientNumber = ""
            showAddSheet = false
        } catch {
            errorAlert = AlertError(message: error.localizedDescription)
        }
    }
}
