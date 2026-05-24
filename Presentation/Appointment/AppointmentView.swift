
import SwiftUI
import SwiftData

struct AppointmentView: View {
    
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var viewModel: AppointmentViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
   
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var icsCoordinator: ICSImportCoordinator
    @Environment(\.modelContext) private var modelContext
    
    
    @State private var showingManualEntry = false
    @State private var showingPlanner = false
    @State private var showingCalendarOnboarding = false
    @State private var showingEmailImport = false
    @State private var emailText = ""
    @State private var showingImportResults = false
    @State private var importResults: AppointmentChanges? = nil
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var showReminderSettings = false
  
    
    @State private var dayDate: DayPlannerDate? = nil       // Day-Ebene
    @State private var showingYear = false                   // Year-Ebene
    @State private var plannerMonthAnchor: Date = Date()     //
    @State private var yearMonth: Date? = nil
    
    // Planner-ViewModel aus AppDependencies
    @StateObject private var plannerVM = AppDependencies.shared.makeAppointmentPlannerViewModel()

    @Query private var allAppointments: [Appointment]
        
    private var appointments: [Appointment] {
        guard let currentUserId = session.currentUser?.id else {
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
                    showingManualEntry: { handleNewAppointmentTap() },     // 🔄 geändert
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
        .navigationTitle("")
        .toolbar {
            AppointmentToolbar(
                showingManualEntry: { handleNewAppointmentTap() },         // 🔄 geändert
                showingEmailImport: { showingEmailImport = true },
                showingProfile: { showProfile = true },
                showingReminders: { showReminderSettings = true },
                notificationsEnabled: session.currentUser?.appointmentReminderEnabled ?? false,
                session: session
            )
        }
        // 🆕 Permission-Onboarding
        .sheet(isPresented: $showingCalendarOnboarding) {
            CalendarPermissionOnboardingSheet(
                onAllow: {
                    await plannerVM.requestAccess()
                    if plannerVM.permissionState == .authorized {
                        showingPlanner = true
                    } else {
                        showingManualEntry = true
                    }
                },
                onSkip: {
                    plannerVM.skipOnboarding()
                    showingManualEntry = true
                }
            )
        }
        // 🆕 Calendar-Planner (Year <- Month → Day)
        
       .fullScreenCover(isPresented: $showingPlanner) {
           AppointmentMonthView(
               viewModel: plannerVM,
               initialMonth: plannerMonthAnchor,
               onDaySelected: { date in
                   // Month schließen, Day öffnen – im gleichen Render-Cycle
                   showingPlanner = false
                   dayDate = DayPlannerDate(date: date)
               },
               onYearTapped: {
                   showingPlanner = false
                   showingYear = true
               },
               onCloseAll: {
                   showingPlanner = false
               }
           )
       }
       .fullScreenCover(item: $dayDate) { wrapper in
           AppointmentDayView(
               viewModel: plannerVM,
               initialDay: wrapper.date,
               onBackToMonth: { lastDay in
                   // Day schließen, Month wieder öffnen – mit Monat des angeschauten Tags
                   plannerMonthAnchor = lastDay
                   dayDate = nil
                   showingPlanner = true
               },
               onCloseAll: {
                   dayDate = nil
               }
           )
       }
   
       .fullScreenCover(isPresented: $showingYear) {
           AppointmentYearView(
               viewModel: plannerVM,
               onMonthSelected: { selectedMonth in
                   // YearView schließen, MonthView mit Monat öffnen
                   plannerMonthAnchor = selectedMonth
                   showingYear = false
                   showingPlanner = true
               },
               onCloseAll: {
                   showingYear = false
               }
           )
       }
       
        // Bestehender Manual-Entry (Fallback wenn Permission denied)
        .sheet(isPresented: $showingManualEntry) {
            ManualAppointmentEntryView()
        }
        .fullScreenCover(item: $importResults) { changes in
                    ImportResultsView(changes: changes) { keep, delete in
                        Task { await viewModel.applyImportDecisions(keep: keep, delete: delete) }
                    }
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
// ICS-Import: reagiert, sobald eine .ics per "Öffnen mit" ankommt.
        // NEU
                .onChange(of: icsCoordinator.pendingFileURL) { _, url in
                    guard url != nil else { return }
                    Task { await runICSImport() }
                
                }

              
    }
    
    // MARK: - Handler
    
    /// Routet zum richtigen Sheet basierend auf Calendar-Permission
    private func handleNewAppointmentTap() {
        plannerVM.refreshPermissionState()
        switch plannerVM.permissionState {
        case .authorized:
            showingPlanner = true
        case .needsOnboarding:
            showingCalendarOnboarding = true
        case .denied, .restricted, .unknown:
            showingManualEntry = true
        }
    }
    
    // NEU
        /// Führt den ICS-Import aus. Liest die wartende Datei über den
        /// Coordinator, ruft das ViewModel und zeigt dasselbe Ergebnis-Sheet
        /// wie der Email-Import.
        private func runICSImport() async {
            guard let icsText = icsCoordinator.readPendingFileContents() else {
                icsCoordinator.clear()
                return
            }
            do {
                let changes = try await viewModel.parseAppointmentsFromICS(
                    icsText
                )
                importResults = changes          // löst dein bestehendes Ergebnis-Sheet aus
                icsCoordinator.clear()
                // NEU
                            } catch {
                                // Fängt auch ICSImportError.notAnAgilFile – fremde Dateien
                                // werden hart abgelehnt. Das ViewModel hat die Fehlermeldung
                                // schon gesetzt (setError), die UI zeigt sie über hasError.
                                print("❌ ICS import failed: \(error)")
                                icsCoordinator.clear()
                            }
        }
    
    private struct DayPlannerDate: Identifiable {
        let date: Date
        var id: Date { date }
    }
}

// MARK: - Preview
#Preview {
    let container = PreviewHelper.createModelContainer()
       let userRepository = UserRepository(modelContext: container.mainContext)
       let authenticator = LocalAuthBiometricAuthenticator()
       let preferences = UserDefaultsBiometricPreferences()
       let unlockUseCase = UnlockAppUseCase(
           authenticator: authenticator,
           preferences: preferences
       )
       let sessionManager = SessionManager(
           userRepository: userRepository,
           unlockUseCase: unlockUseCase,
           preferences: preferences
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
