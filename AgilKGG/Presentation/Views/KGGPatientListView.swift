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
    @StateObject private var viewModel: KGGPatientListViewModel
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
                emptyStateView
            } else {
                patientListView
            }
        }
        .navigationTitle("Patienten")
        .navigationBarTitleDisplayMode(.large)
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
            addPatientSheet
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

    // MARK: - Patient List

    private var patientListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                countCard
                    .padding(.horizontal, 16)

                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredPatients) { patient in
                        NavigationLink {
                            KGGPatientDetailView(patient: patient, modelContext: modelContext)
                                .environmentObject(themeManager)
                        } label: {
                            patientCard(patient)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
        }
    }

    private var countCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Patienten")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.allPatients.count) gesamt")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Spacer()
            Image(systemName: "person.2.fill")
                .font(.headline)
                .foregroundStyle(accent)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func patientCard(_ patient: KGGPatient) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.patientNumber)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("\(patient.exercises.count) Übungen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if !patient.diagnosis.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Diagnose")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(patient.diagnosis)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }

            if patient.exercises.count > 0 {
                HStack(spacing: 8) {
                    ForEach(patient.exercises.prefix(3)) { exercise in
                        VStack(spacing: 2) {
                            Text("\(exercise.reps)x")
                                .font(.caption2)
                                .fontWeight(.bold)
                            Text("\(Int(exercise.weight))kg")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accent.opacity(0.1))
                        .cornerRadius(8)
                    }
                    if patient.exercises.count > 3 {
                        Text("+\(patient.exercises.count - 3)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .contextMenu {
            Button(role: .destructive) {
                deletePatient(patient)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
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

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(accent.opacity(0.6))

            VStack(spacing: 8) {
                Text("Keine Patienten")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Fügen Sie einen Patienten hinzu, um zu starten")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddSheet = true
            } label: {
                Label("Patient hinzufügen", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(accent)
                    .cornerRadius(12)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Add Sheet

    private var addPatientSheet: some View {
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
                            .background(newPatientNumber.isEmpty ? Color(.systemGray3) : accent)
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

    private func deletePatient(_ patient: KGGPatient) {
        do {
            try viewModel.deletePatient(patient)
        } catch {
            errorAlert = AlertError(message: error.localizedDescription)
        }
    }
}

// MARK: - Helper

struct AlertError: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KGGPatient.self, configurations: config)
    return NavigationStack {
        KGGPatientListView(
            modelContext: container.mainContext,
            praxisId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        )
        .environmentObject(ThemeManager())
        .environmentObject(KGGAuthViewModel())
    }
}
