// Features/Appointments/Presentation/Views/AppointmentView.swift
import SwiftUI
import SwiftData

struct AppointmentView: View {
    
    
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var viewModel: AppointmentViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    
    
    @EnvironmentObject var authService: AuthService
    @Environment(\.modelContext) private var modelContext
    
  
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
            ManualAppointmentEntryView()
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
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

}
// MARK: - Preview
#Preview {
    let container = PreviewHelper.createModelContainer()
    let authService = AuthService(authServiceProtocol: MockAuthService())
    let settingsVM = SettingsViewModel(modelContext: container.mainContext, authService: authService)
    
    AppointmentView()  // ← kein Parameter mehr
        .modelContainer(container)
        .environmentObject(authService)
        .environmentObject(settingsVM)
        .environmentObject(PreviewHelper.createAppointmentViewModel())
        .environmentObject(ProfileViewModel(modelContext: container.mainContext, authService: authService))
}


