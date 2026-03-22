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
    @State private var importResults: AppointmentChanges? = nil
    @State private var showProfile = false
    @State private var showSettings = false

    @Query private var allAppointments: [Appointment]
        
    // ✅ Filter in computed property
       private var appointments: [Appointment] {
           guard let currentUserId = authService.currentUser?.id else {
               print("⚠️ Kein User eingeloggt - keine Termine")
               return []
           }
           
           
           return allAppointments.filter { appointment in
               appointment.userId == currentUserId
           }
                   .sorted { $0.date < $1.date }
           
       }
       
       // ✅ Init mit User-Filter
       init(viewModel: AppointmentViewModel) {
           _viewModel = StateObject(wrappedValue: viewModel)
           
           // ✅ Query mit User-Filter (wird bei jedem View-Init neu erstellt)
           let userId = viewModel.authService.currentUser?.id ?? UUID()
           
           _allAppointments = Query(
               filter: #Predicate<Appointment> { appointment in
                   appointment.userId == userId
               },
               sort: \Appointment.date
           )
       }
    
    var body: some View {
        
        Group {
            if appointments.isEmpty {
                EmptyStateView(
                    showingManualEntry: { showingManualEntry = true },
                    showingEmailImport: { showingEmailImport = true }
                )
            } else {
                AppointmentsList(
                    appointments: appointments,
                    viewModel: viewModel
                )
            }
        }
        .background(Color(.systemGroupedBackground))  // ← statt ZStack
        .navigationTitle("Termine")
        .toolbar {
               AppointmentToolbar(
                   showingManualEntry: { showingManualEntry = true },
                   showingEmailImport: { showingEmailImport = true },
                   showingProfile: { showProfile = true },
                   showingSettings: { showSettings = true },
                   authService: authService
               )
           }
        
        .sheet(isPresented: $showingManualEntry) {
            ManualAppointmentEntryView(viewModel: viewModel)
        }
 /*       .sheet(isPresented: $showingEmailImport) {
            EmailImportView(
                emailText: $emailText,
                onImport: {
                    Task {
                        do {
                            let changes = try await viewModel.parseAppointmentsFromEmail(emailText)
                            
                            // ✅ Results setzen
                            importResults = changes
                            emailText = ""
                            
                            // ✅ Email-Sheet schließen
                            showingEmailImport = false
                            
                            // ✅ Kurz warten
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            
                            // Results-Sheet öffnet sich automatisch durch sheet(item:)!
                            
                        } catch {
                            print("❌ Error: \(error)")
                            showingEmailImport = false
                        }
                    }
                },
                onDismiss: {
                    showingEmailImport = false
                    emailText = ""
                }
            )
        }*/
        // ✅ Öffnet automatisch, wenn importResults != nil
        .sheet(item: $importResults) { changes in
            ImportResultsView(changes: changes)
                .presentationDetents([.medium, .large])
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
            ProfileView()
                .environmentObject(authService)
                .environment(\.modelContext, profileVM.modelContext)
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
    let authService = AuthService(authServiceProtocol: MockAuthService())
   
    
    AppointmentView(viewModel: PreviewHelper.createAppointmentViewModel())
        .modelContainer(container)
        .environmentObject(settingsVM)
        .environmentObject(authService)
   
}


