// Features/Appointments/Presentation/Views/AppointmentView.swift
import SwiftUI
import SwiftData

struct AppointmentView: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @EnvironmentObject var authService: AuthService
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settingsVM: SettingsViewModel
    
    @StateObject private var viewModel: AppointmentViewModel
    @State private var showingManualEntry = false
    @State private var showingEmailImport = false
    @State private var emailText = ""
    @State private var showingImportResults = false
    @State private var importResults: AppointmentChanges?
    @State private var showProfile = false
    @State private var showSettings = false
    
    
    
    // ✅ CLEAN: ViewModel wird von außen übergeben
    init(viewModel: AppointmentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        
    }
    
    var body: some View {
        
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            if viewModel.appointments.isEmpty {
                EmptyStateView(
                    showingManualEntry: { showingManualEntry = true },
                    showingEmailImport: { showingEmailImport = true }
                )
            } else {
                AppointmentsList(viewModel: viewModel) 
            }
        }
        .navigationTitle("Termine")
        
        
        .toolbar {
               AppointmentToolbar(
                   showingManualEntry: { showingManualEntry = true },
                   showingEmailImport: { showingEmailImport = true },
                   showingProfile: { showProfile = true },
                   showingSettings: { showSettings = true }
               )
           }
        
        .sheet(isPresented: $showingManualEntry) {
            ManualAppointmentEntryView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingEmailImport) {
            EmailImportView(
                emailText: $emailText,
                onImport: {
                    // ✅ Task für async Funktion
                    Task {
                       try await viewModel.parseAppointmentsFromEmail(emailText)
                        showingEmailImport = false
                        showingImportResults = true
                        emailText = ""
                    }
                },
                onDismiss: {
                    showingEmailImport = false
                    emailText = ""
                }
            )
        }
        .sheet(isPresented: $showingEmailImport) {
            EmailImportView(
                emailText: $emailText,
                onImport: {
                    Task {
                        do {
                            // ✅ NEUE Methode mit Return
                            let changes = try await viewModel.parseAppointmentsFromEmail(emailText)
                            
                            // ✅ Results speichern
                            importResults = changes
                            
                            // ✅ UI updaten
                            showingEmailImport = false
                            showingImportResults = true
                            emailText = ""
                            
                        } catch {
                            print("❌ Email import failed: \(error)")
                            // Optional: Error dem User zeigen
                            viewModel.setError(.parsingFailed(error.localizedDescription))
                        }
                    }
                },
                onDismiss: {
                    showingEmailImport = false
                    emailText = ""
                }
            )
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(profileVM: profileVM) // Profil View mit dem richtigen Parameter erstellen
                      .environment(\.modelContext, settingsVM.modelContext)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settingsVM)  // falls SettingsView das braucht
                .environment(\.modelContext, modelContext)
            
            
        }
    }

}
// MARK: - Preview
#Preview {
    let container = PreviewHelper.createModelContainer()
    let settingsVM = SettingsViewModel(modelContext: container.mainContext, authService: AppDependencies.shared.authService)
   
    
    AppointmentView(viewModel: PreviewHelper.createAppointmentViewModel())
        .modelContainer(container)
        .environmentObject(settingsVM)  // ← DEFINIERT!
   
}


