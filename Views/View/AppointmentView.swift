// Features/Appointments/Presentation/Views/AppointmentView.swift
import SwiftUI
import SwiftData

struct AppointmentView: View {
  
    @State private var viewModel: AppointmentViewModel
    @State private var showingManualEntry = false
    @State private var showingEmailImport = false
    @State private var emailText = ""
    @State private var showingImportResults = false
    @State private var importResults: AppointmentChanges?
    
    @State private var showProfile = false
    @State private var showSettings = false
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settingsVM: SettingsViewModel
    let currentUser: User
    
    // ✅ CLEAN: ViewModel wird von außen übergeben
    init(viewModel: AppointmentViewModel, currentUser: User) {
        _viewModel = State(initialValue: viewModel)
        self.currentUser = currentUser
    }
    
    var body: some View {
        
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            if viewModel.appointments.isEmpty {
                EmptyStateView(
                    showingManualEntry: {
                        showingManualEntry = true
                    },
                    showingEmailImport: {
                        showingEmailImport = true
                    }
                )
            } else {
                appointmentsList
            }
        }
        .navigationTitle("Termine")
        .toolbar { toolbarContent }
         
                .sheet(isPresented: $showingManualEntry) {
                    ManualAppointmentEntryView(viewModel: viewModel)
                }
                .sheet(isPresented: $showingEmailImport) {
                    EmailImportView(
                        emailText: $emailText,
                        onImport: {
                            // ✅ Task für async Funktion
                            Task {
                                await viewModel.parseAppointmentsFromEmail(emailText)
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
                .sheet(isPresented: $showingImportResults) {
                    if let results = importResults {
                        ImportResultsView(changes: results)
                    }
                }
                .sheet(isPresented: $showProfile) {
                    ProfileView()
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(user: currentUser)  // oder settingsVM.user falls verfügbar
                        .environmentObject(settingsVM)  // falls SettingsView das braucht
                        .environment(\.modelContext, modelContext)
                    
                }
            }
        
// NEUE computed property für Toolbar:
@ToolbarContentBuilder
private var toolbarContent: some ToolbarContent {
    // LINKS: Plus-Menü
    ToolbarItem(placement: .navigationBarLeading) {
        Menu {
            Button("Manuell eintragen") { showingManualEntry = true }
            Button("Aus Email importieren") { showingEmailImport = true }
        } label: {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.accent)
                .font(.title3)
        }
    }
    
    // RECHTS: Profile-Menü
    ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
            Button("Profil") { showProfile = true }
            Button("Einstellungen") { showSettings = true }
        } label: {
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        }
    }
}
 
    
    // MARK: - Appointments List
    private var appointmentsList: some View {
       
        ScrollView {
            VStack(spacing: 16) {
                // Next Appointment Card
                if let next = viewModel.nextAppointment {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Nächster Termin")
                                .font(.headline)
                            Spacer()
                        }
                        
                        AppointmentCardView(
                                               appointment: next,
                                               isNext: true,
                                               onDelete: {
                                                   Task {
                                                       await viewModel.deleteAppointment(next)
                                                   }
                                               }
                                           )
                            .onTapGesture {
                                // Navigation zur Detail-Ansicht
                            }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                
                // Upcoming Appointments
                if !viewModel.otherUpcomingAppointments.isEmpty {
                    VStack(alignment: .leading, spacing: 12)
                    {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.accent)
                            Text("Kommende Termine")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.otherUpcomingAppointments.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                        
                        ForEach(viewModel.otherUpcomingAppointments) { appointment in
                                                   AppointmentCardView(
                                                       appointment: appointment,
                                                       isNext: false,
                                                       onDelete: {
                                                           Task {
                                                               await viewModel.deleteAppointment(appointment)
                                                           }
                                                       }
                                                   )
                                               }
                                           }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
                }
                
                // Past Appointments
                if !viewModel.pastAppointments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.secondary)
                            Text("Vergangene Termine")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.pastAppointments.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                        
                        ForEach(viewModel.pastAppointments) { appointment in
                                                AppointmentCardView(
                                                    appointment: appointment,
                                                    isNext: false,
                                                    onDelete: {
                                                        Task {
                                                            await viewModel.deleteAppointment(appointment)
                                                        }
                                                    }
                                                )
                                                .opacity(0.6)
                                            }
                                        }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
                }
                Spacer(minLength: 40)
                
                
            }
        }
    }
 
    // MARK: - Import Results View
    struct ImportResultsView: View {
        @Environment(\.dismiss) private var dismiss
        let changes: AppointmentChanges
        
        var body: some View {
            NavigationStack {
                List {
                    if !changes.added.isEmpty {
                        Section("Neue Termine (\(changes.added.count))") {
                            ForEach(changes.added) { appointment in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appointment.therapist)
                                        .font(.headline)
                                    Text(appointment.formattedDateTime)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    if !changes.modified.isEmpty {
                        Section("Geänderte Termine (\(changes.modified.count))") {
                            ForEach(changes.modified) { appointment in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appointment.therapist)
                                        .font(.headline)
                                    Text(appointment.formattedDateTime)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    if !changes.cancelled.isEmpty {
                        Section("Abgesagte Termine (\(changes.cancelled.count))") {
                            ForEach(changes.cancelled) { appointment in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appointment.therapist)
                                        .font(.headline)
                                    Text(appointment.formattedDateTime)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    if changes.added.isEmpty && changes.modified.isEmpty && changes.cancelled.isEmpty {
                        Section {
                            Text("Keine neuen Termine gefunden")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("Import-Ergebnisse")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Fertig") {
                            dismiss()
                        }
                    }

                }
            }
        }
    }
}
// MARK: - Preview
#Preview {
    
    let container = PreviewHelper.createModelContainer()
    
    let testUser = User(
        id: UUID(),
        email: "test@example.com",
        passwordHash: "hashedPassword123"
    )
    
    let settingsVM = SettingsViewModel(user: testUser, modelContext: container.mainContext)
    
    
    AppointmentView(
        viewModel: PreviewHelper.createAppointmentViewModel(), currentUser: testUser)
    .modelContainer(container)
    .environmentObject(settingsVM)
}
