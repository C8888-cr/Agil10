//
//  KGGPatientListView.swift
//  AgilKGG
//
//  Patient-Liste: Cards wie LibraryView (Schatten), Suchen, Hinzufügen, Löschen
//

import SwiftUI
import SwiftData
import AgilCore

struct KGGPatientListView: View {
    @StateObject var viewModel: KGGPatientListViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    @State private var showAddSheet = false
    @State private var newPatientNumber = ""
    @State private var errorAlert: AlertError?

    private var accent: Color { themeManager.currentTheme.accentColor }

    init(modelContext: ModelContext, praxisId: UUID) {
        _viewModel = StateObject(wrappedValue: KGGPatientListViewModel(modelContext: modelContext, praxisId: praxisId))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if viewModel.isLoading && viewModel.filteredPatients.isEmpty {
                loadingView
            } else if viewModel.filteredPatients.isEmpty {
                EmptyStateView()
            } else {
                PatientListView( viewModel: viewModel)
            }
        }
        .navigationTitle("Patienten")
        .navigationBarTitleDisplayMode(.inline)

        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Patient suchen..."
        )
        .onChange(of: viewModel.searchText) {
            viewModel.applySearch()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(accent)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                KGGLogoMenu()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddPatientSheet(viewModel: viewModel)
        }
        .alert("Fehler", isPresented: .constant(errorAlert != nil), presenting: errorAlert) { _ in
            Button("OK") { errorAlert = nil }
        } message: { error in
            Text(error.message)
        }
        .onAppear {
            viewModel.loadPatients()
        }
    }

 
  

 
    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Patienten werden geladen…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

  
  

  
}



