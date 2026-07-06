//
//  PatientListView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 29.06.26.
//

import SwiftUI
import Foundation
import AgilCore
import SwiftData

struct PatientListView: View {
    
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: KGGPatientListViewModel
    @State private var errorAlert: AlertError?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CountCard(count: viewModel.allPatients.count)
                    .padding(.horizontal, 16)
                
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredPatients) { patient in
                        NavigationLink {
                            KGGPatientDetailView(patient: patient, modelContext: modelContext)
                                .environmentObject(themeManager)
                        } label: {
                            PatientCard(patient: patient,
                            onDelete: {
                                deletePatient(patient)
                            })
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
        }
        
    }
    private func deletePatient(_ patient: KGGPatient) {
        do {
            try viewModel.deletePatient(patient)
        } catch {
            errorAlert = AlertError(message: error.localizedDescription)
        }
    }
}
