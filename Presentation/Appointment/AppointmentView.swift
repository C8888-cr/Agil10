import SwiftUI
import SwiftData

struct AppointmentView: View {
    
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var viewModel: AppointmentViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @EnvironmentObject var session: SessionManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingManualEntry = false
    @State private var showingEmailImport = false
    @State private var emailText = ""
    @State private var showingImportResults = false
    @State private var importResults: AppointmentChanges? = nil
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var showReminderSettings = false

    @Query private var allAppointments: [Appointment]
        
    private var appointments: [Appointment] {
        guard let currentUserId = session.currentUser?.id else {  // ← session
            print("⚠️ Kein User eingeloggt - keine Termine")
            return []
        }
        return allAppointments
            .filter { $0.userId == currentUserId }
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
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Termine")
        .toolbar {
            AppointmentToolbar(
                showingManualEntry: { showingManualEntry = true },
                showingEmailImport: { showingEmailImport = true },
                showingProfile: { showProfile = true },
            
                showingReminders: { showReminderSettings = true },
                notificationsEnabled: session.currentUser?.appointmentReminderEnabled ?? false,  
                session: session
            )
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualAppointmentEntryView()
        }
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
                            let changes = try await viewModel.parseAppointmentsFromEmail(emailText)
                            importResults = changes
                            showingEmailImport = false
                            showingImportResults = true
                            emailText = ""
                        } catch {
                            print("❌ Email import failed: \(error)")
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

        .sheet(isPresented: $showReminderSettings) {
            if let user = session.currentUser {
                AppointmentReminderSheet(
                    user: user,
                    appointments: appointments
                )
            }
        
        }
    }
}

// MARK: - Preview
#Preview {
    let container = PreviewHelper.createModelContainer()
    let sessionManager = SessionManager(
        userRepository: UserRepository(modelContext: container.mainContext)
    )
    let context = ModelContext(container)

    let repository = VideoScheduleRepository(modelContext: context)
    let settingsVM = SettingsViewModel(
        modelContext: context,
        session: sessionManager,
        addScheduleUseCase: AddScheduleUseCase(repository: repository),
        removeScheduleUseCase: RemoveScheduleUseCase(repository: repository)
    )
    
    AppointmentView()
        .modelContainer(container)
        .environmentObject(sessionManager)
        .environmentObject(settingsVM)
        .environmentObject(PreviewHelper.createAppointmentViewModel())
        .environmentObject(ProfileViewModel(
            userRepository: UserRepository(modelContext: container.mainContext),
            session: sessionManager
        ))
}
