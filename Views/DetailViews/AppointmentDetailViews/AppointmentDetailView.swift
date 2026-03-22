//
//  AppointmentDetailView.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


// Features/Appointments/Presentation/Views/AppointmentDetailView.swift
import SwiftUI
import MapKit
import SwiftData


struct AppointmentDetailView: View {
    @EnvironmentObject var authService: AuthService
    
    @Environment(\.dismiss) private var dismiss
    let appointment: Appointment
    let viewModel: AppointmentViewModel
    
    @State private var showingCancelSheet = false
    @State private var cancelReason = ""
    
    @State private var showEmailSentConfirmation = false

    
    private var userEmail: String {
          authService.currentUser?.email ?? ""
      }

    
    private var region: MKCoordinateRegion {
        if let coordinate = appointment.coordinate {
            return MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(spacing: 24) {
                    
                    
                    // Header Card
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.accent, .accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(appointment.formattedDate)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(appointment.formattedTime)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.accent.opacity(0.1),
                                Color.accent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    
                    
                    // Therapeut Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Therapeut", systemImage: "person.fill")
                            .font(.headline)
                        
                        Text(appointment.therapist)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    
                    
                    // Location Section
                    if appointment.locationName != nil || appointment.locationAddress != nil {
                        LocationSection(
                            appointment: appointment,
                            showMap: appointment.coordinate != nil,
                            region: region
                        )
                        .padding()
                        .background(
                            Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                                                }
                                                
                      // Notes Section
                      if let notes = appointment.notes {
                         VStack(alignment: .leading, spacing: 12) {
                            Label("Notizen", systemImage: "note.text")
                                .font(.headline)
                                                        
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                                                    }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                                                
                        // Status Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Status", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                                    
                            HStack {
                                Circle()
                                    .fill(appointment.status.color)
                                    .frame(width: 12, height: 12)
                                                        
                                Text(appointment.status.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                            }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                                
                    
                            // Actions
                                if appointment.status != .cancelled {
                                    Button(action: {
                                        showingCancelSheet = true
                                                    }) {
                                    Label("Termin absagen", systemImage: "xmark.circle.fill")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.red)
                                            .cornerRadius(12)
                                                    }
                                            .padding(.horizontal)
                                        }
                                                
                                    Spacer(minLength: 20)
                                }
                        .padding(.vertical)
                    }
                .background(Color(.systemGroupedBackground))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fertig") {
                            dismiss()
                                                }
                                                .fontWeight(.semibold)
                                            }
                                        }
                                        .sheet(isPresented: $showingCancelSheet) {
                                            CancelAppointmentView(
                                                appointment: appointment,
                                                viewModel: viewModel,
                                                isPresented: $showingCancelSheet
                                            )
                                            .environmentObject(authService) 
                                        }
                                    }
                                }
                            }

/*
                            // MARK: - Cancel Appointment View
                            struct CancelAppointmentView: View {
                                
                                @EnvironmentObject var authService: AuthService
                                @Environment(\.dismiss) private var dismiss
                                
                                private var userEmail: String {
                                    authService.currentUser?.email ?? ""
                                }
                                
                                let appointment: Appointment
                                let viewModel: AppointmentViewModel
                                
                                
                                @Binding var isPresented: Bool
                           
                                
                                @State private var cancelReason = ""
                                @State private var isProcessing = false
                                
                                var body: some View {
                                    NavigationStack {
                                        Form {
                                            Section("Grund der Absage") {
                                                TextEditor(text: $cancelReason)
                                                    .frame(minHeight: 100)
                                            }
                                            
                                            Section {
                                                Button(action: cancelAppointment) {
                                                    if isProcessing {
                                                        HStack {
                                                            Spacer()
                                                            ProgressView()
                                                                .progressViewStyle(.circular)
                                                            Text("Absage wird gesendet...")
                                                                .foregroundColor(.secondary)
                                                            Spacer()
                                                        }
                                                    } else {
                                                        HStack {
                                                            Spacer()
                                                            Text("Termin absagen")
                                                                .fontWeight(.semibold)
                                                            Spacer()
                                                        }
                                                    }
                                                }
                                                .disabled(cancelReason.isEmpty || isProcessing)
                                                .foregroundColor(.red)
                                            }
                                            
                                            Section {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    HStack {
                                                        Image(systemName: "info.circle.fill")
                                                            .foregroundColor(.blue)
                                                        Text("Hinweis")
                                                            .font(.headline)
                                                    }
                                                    
                                                    Text("Eine Absage-Email wird automatisch an die Praxis gesendet.")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        .navigationTitle("Termin absagen")
                                        .navigationBarTitleDisplayMode(.inline)
                                        .toolbar {
                                            ToolbarItem(placement: .navigationBarLeading) {
                                                Button("Abbrechen") {
                                                    dismiss()
                                                }
                                            }
                                        }
                                    }
                                }
 private func cancelAppointment() {
     isProcessing = true
     
     Task {
        await viewModel.cancelAppointment(appointment, reason: cancelReason, userEmail: userEmail)
         
         await MainActor.run {
             isProcessing = false
             isPresented = false
             dismiss()
         }
     }
 }
}
                               */





struct CancelAppointmentView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    let appointment: Appointment
    let viewModel: AppointmentViewModel
    @Binding var isPresented: Bool
    
    @State private var cancelReason = ""
    @State private var isProcessing = false
    @State private var showLateWarning = false
    @State private var selectedEmailApp: EmailApp = .default
    
    // ✅ Prüfen ob weniger als 24h bis zum Termin
    private var isLessThan24Hours: Bool {
        appointment.date.timeIntervalSinceNow < 86400
    }
    
    @State private var showEmailSentConfirmation = false
    
    enum EmailApp: String, CaseIterable, Identifiable {
        case `default` = "Mail"
        case gmail = "Gmail"
        case outlook = "Outlook"
        
        var id: String { rawValue }
        
        var urlScheme: String {
            switch self {
            case .default: return "mailto"
            case .gmail: return "googlegmail"
            case .outlook: return "ms-outlook"
            }
        }
        
        var isAvailable: Bool {
            guard let url = URL(string: "\(urlScheme)://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }
    
    private var availableEmailApps: [EmailApp] {
        EmailApp.allCases.filter { $0.isAvailable }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // ✅ 24h Warnung
                if isLessThan24Hours {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Kurzfristige Absage")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                Text("Der Termin ist in weniger als 24 Stunden. Eine Absagegebühr kann anfallen.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Grund der Absage") {
                    TextEditor(text: $cancelReason)
                        .frame(minHeight: 100)
                }
                
                // ✅ Email-App Auswahl
                if availableEmailApps.count > 1 {
                    Section("Email senden mit") {
                        Picker("Email-App", selection: $selectedEmailApp) {
                            ForEach(availableEmailApps) { app in
                                Text(app.rawValue).tag(app)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section {
                    Button(action: handleCancel) {
                        if isProcessing {
                            HStack {
                                Spacer()
                                ProgressView()
                                Text("Absage wird gesendet...")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Termin absagen")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(isProcessing)
                    .foregroundColor(.red)
                }
                
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Eine Absage-Email wird an die Praxis gesendet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Termin absagen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            // ✅ 24h Bestätigungs-Alert
            .confirmationDialog(
                "Kurzfristige Absage",
                isPresented: $showLateWarning,
                titleVisibility: .visible
            ) {
                Button("Trotzdem absagen", role: .destructive) {
                    performCancel()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Der Termin ist in weniger als 24 Stunden. Eine Absagegebühr kann anfallen. Möchtest du trotzdem absagen?")
            }
            
            .confirmationDialog(
                "Email abgeschickt?",
                isPresented: $showEmailSentConfirmation,
                titleVisibility: .visible
            ) {
                Button("Ja, Email wurde gesendet") {
                    Task {
                        await viewModel.cancelAppointment(
                            appointment,
                            reason: cancelReason,
                            userEmail: authService.currentUser?.email ?? ""
                        )
                        await MainActor.run {
                            isPresented = false
                            dismiss()
                        }
                    }
                }
                Button("Nein, nicht gesendet", role: .cancel) {
                    // Status wird NICHT gesetzt
                }
            } message: {
                Text("Wurde die Absage-Email an die Praxis gesendet?")
            }
        }
    }
    
    private func handleCancel() {
        if isLessThan24Hours {
            showLateWarning = true
        } else {
            performCancel()
        }
    }
    
    private func performCancel() {
        isProcessing = true
        
        let userEmail = authService.currentUser?.email ?? ""
        
        sendEmailWithSelectedApp(userEmail: userEmail) { success in
            isProcessing = false
            if success {
                // ✅ Mail-App geöffnet → User fragen ob gesendet
                showEmailSentConfirmation = true
            }
        }
    }
    
    private func sendEmailWithSelectedApp(userEmail: String, completion: @escaping (Bool) -> Void) {
        let practiceEmail: String
        if let praxisId = authService.currentUser?.praxisId,
           let praxis = PraxisDataManager.shared.getPraxis(by: praxisId),
           let email = praxis.email {
            practiceEmail = email
        } else {
            practiceEmail = "praxis@physio-agil.de"
        }
        
        let subject = "Terminabsage - \(appointment.dateString)"
        var body = """
        Sehr geehrte Damen und Herren,
        
        hiermit möchte ich meinen Termin absagen:
        
        Datum: \(appointment.dateString)
        Uhrzeit: \(appointment.timeString)
        Therapeut: \(appointment.therapist)
        """
        if !cancelReason.isEmpty {
            body += "\n\nGrund: \(cancelReason)"
        }
        body += "\n\nMit freundlichen Grüßen\n\(userEmail)"
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString: String
        switch selectedEmailApp {
        case .default:
            urlString = "mailto:\(practiceEmail)?subject=\(encodedSubject)&body=\(encodedBody)"
        case .gmail:
            urlString = "googlegmail://co?to=\(practiceEmail)&subject=\(encodedSubject)&body=\(encodedBody)"
        case .outlook:
            urlString = "ms-outlook://compose?to=\(practiceEmail)&subject=\(encodedSubject)&body=\(encodedBody)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url) { success in
                completion(success)
            }
        }
    }
}
                            // MARK: - Manual Appointment Entry
struct ManualAppointmentEntryView: View {
    
    @EnvironmentObject var authService: AuthService
    
    @Environment(\.dismiss) private var dismiss
    let viewModel: AppointmentViewModel
    
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var therapistName = ""
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedTherapistId: UUID? = nil
    @State private var isManualTherapist = false
    
    // ❌ selectedPraxisId entfernt — Praxis kommt fest aus dem Profil
    
    private var userPraxis: Praxis? {
        guard let praxisId = authService.currentUser?.praxisId else { return nil }
        return PraxisDataManager.shared.praxen.first { $0.id == praxisId }
    }
    
    // Therapeuten der Praxis aus dem Profil
    private var availableTherapists: [Therapeut] {
        guard let praxisId = authService.currentUser?.praxisId else { return [] }
        return TherapeutDataManager.shared.getTherapeutenForPraxis(praxisId)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                
                // MARK: - Termin-Details
                Section("Termin-Details") {
                    DatePicker(
                        "Datum",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    
                    DatePicker(
                        "Uhrzeit",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                }
                
                // MARK: - Praxis (fest aus Profil)
                Section {
                    if let praxis = userPraxis {
                        // Praxis-Name wie in PraxisCard
                        Text(praxis.name)
                            .font(.title3.bold())
                            .foregroundStyle(Color.accentColor)
                    } else {
                        Text("Keine Praxis im Profil hinterlegt")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Praxis")
                } footer: {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Du kannst deine Praxis in deinem Profil ändern.")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                // MARK: - Therapeut Picker
                Section("Therapeut") {
                    Picker("Therapeut auswählen", selection: $selectedTherapistId) {
                        Text("Kein Therapeut ausgewählt")
                            .tag(nil as UUID?)
                        
                        if !availableTherapists.isEmpty {
                            ForEach(availableTherapists) { therapeut in
                                Text(therapeut.fullName)
                                    .tag(therapeut.id as UUID?)
                            }
                        }
                        
                        Text("Manuell eintragen")
                            .tag(UUID(uuidString: "00000000-0000-0000-0000-000000000001") as UUID?)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedTherapistId) { _, newId in
                        let manualId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
                        
                        if newId == manualId {
                            isManualTherapist = true
                            therapistName = ""
                        } else if let id = newId,
                                  let therapeut = availableTherapists.first(where: { $0.id == id }) {
                            isManualTherapist = false
                            therapistName = therapeut.fullName
                        } else {
                            isManualTherapist = false
                            therapistName = ""
                        }
                    }
                    
                    // Manuelles Textfeld
                    if isManualTherapist {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil")
                                .foregroundColor(.accent)
                                .font(.caption)
                            TextField("Name des Therapeuten", text: $therapistName)
                                .textContentType(.name)
                        }
                    }
                    
                    // Gewählter Therapeut als Info
                    if !therapistName.isEmpty && !isManualTherapist {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(therapistName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
              
                
                // MARK: - Notizen
                Section("Notizen (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                
                // MARK: - Speichern
                Section {
                    Button(action: saveAppointment) {
                        HStack {
                            Spacer()
                            Text("Termin speichern")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(therapistName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Neuer Termin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .alert("Termin gespeichert", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Dein Termin wurde erfolgreich hinzugefügt.")
            }
            .alert("Fehler", isPresented: $showingError) {  // ← NEU
                  Button("OK", role: .cancel) { }
              } message: {
                  Text(errorMessage)
              }
            .onAppear {
                if let praxis = userPraxis {
                    fillPraxisData(praxis)
                }
            }
        }
    }
    
    private func fillPraxisData(_ praxis: Praxis) {
        locationName = praxis.name
        let street = praxis.addresse ?? ""
        let zip = praxis.postalCode ?? ""
        let city = praxis.city ?? ""
        if !street.isEmpty {
            locationAddress = "\(street), \(zip) \(city)"
                .trimmingCharacters(in: .whitespaces)
        }
    }
    
    private func saveAppointment() {
        guard authService.currentUser != nil else {
            print("❌ Kein User eingeloggt")
            errorMessage = "Nicht eingeloggt"
            showingError = true
            return
        }
        guard !therapistName.trimmingCharacters(in: .whitespaces).isEmpty else {
              errorMessage = "Bitte einen Therapeuten auswählen oder eintragen"
              showingError = true
              return
          }
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        var finalComponents = DateComponents()
        finalComponents.year = dateComponents.year
        finalComponents.month = dateComponents.month
        finalComponents.day = dateComponents.day
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute
        
        guard let finalDate = calendar.date(from: finalComponents) else {
            print("❌ Datum ungültig")
            return
        }
        
        let latitude = userPraxis?.latitude
        let longitude = userPraxis?.longitude
        
        Task {
            print("💾 Speichere Manual Appointment: \(therapistName) am \(finalDate)")
            
            await viewModel.addAppointmentManual(
                date: finalDate,
                therapist: therapistName,
                locationName: locationName.isEmpty ? nil : locationName,
                locationAddress: locationAddress.isEmpty ? nil : locationAddress,
                latitude: latitude,
                longitude: longitude,
                notes: notes.isEmpty ? nil : notes
            )
            
            await MainActor.run {
                print("✅ Appointment gespeichert!")
                showingAlert = true
            }
        }
    }
}

#Preview("Appointment Detail") {
    let viewModel = PreviewHelper.createAppointmentViewModel()
    let appointment = PreviewHelper.createSampleAppointments()[0]
    
    AppointmentDetailView(
        appointment: appointment,
        viewModel: viewModel
    )
    .modelContainer(PreviewHelper.createModelContainer())
}
#Preview("Cancelled Appointment") {
    let viewModel = PreviewHelper.createAppointmentViewModel()
    let appointment = PreviewHelper.createSampleAppointments()[2] // Der abgesagte Termin
    
    return AppointmentDetailView(
        appointment: appointment,
        viewModel: viewModel
    )
    .modelContainer(PreviewHelper.createModelContainer())
}
#Preview {
    let container = PreviewHelper.createModelContainer()
    let authService = PreviewHelper.createMockAuthService()
    let viewModel = PreviewHelper.createAppointmentViewModel
    
    ManualAppointmentEntryView(viewModel: viewModel())
        .environmentObject(authService)
        .modelContainer(container)
}
