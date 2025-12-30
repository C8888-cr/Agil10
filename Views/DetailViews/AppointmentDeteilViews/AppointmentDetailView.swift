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
    
    // ✅ User Email (sollte später aus User Context kommen)
    private let userEmail = "user@example.com"
    
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
                                                isPresented: $showingCancelSheet,
                                                userEmail: userEmail
                                            )
                                        }
                                    }
                                }
                            }
                            // MARK: - Cancel Appointment View
                            struct CancelAppointmentView: View {
                                @Environment(\.dismiss) private var dismiss
                                let appointment: Appointment
                                let viewModel: AppointmentViewModel
                                @Binding var isPresented: Bool
                                let userEmail: String
                                
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
    
    var body: some View {
        NavigationStack {
            Form {
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
                
                Section("Therapeut") {
                    TextField("Name des Therapeuten", text: $therapistName)
                        .textContentType(.name)
                }
                
                Section("Ort (optional)") {
                    TextField("Praxisname", text: $locationName)
                    TextField("Adresse", text: $locationAddress)
                        .textContentType(.fullStreetAddress)
                }
                
                Section("Notizen (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                
                Section {
                    Button(action: saveAppointment) {
                        HStack {
                            Spacer()
                            Text("Termin speichern")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(therapistName.isEmpty)
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
        }
    }
    
    private func saveAppointment() {
        
        // ✅ RICHTIG
        guard let user = authService.currentUser else {
            print("❌ Kein User eingeloggt")
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
        
        guard let finalDate = calendar.date(from: finalComponents) else { return }
        
        
        
        
        // ✅ EXAKTE Reihenfolge wie im Appointment.init
        let newAppointment = Appointment(
            id: UUID(),                                                   // 1
            date: finalDate,                                              // 2
            therapist: therapistName,                                     // 3
            locationName: locationName.isEmpty ? nil : locationName,      // 4
            locationAddress: locationAddress.isEmpty ? nil : locationAddress, // 5 ✅
            locationLatitude: nil,                                        // 6
            locationLongitude: nil,                                       // 7
            notes: notes.isEmpty ? nil : notes,                          // 8 ✅
            emailUID: nil,                                               // 9
            status: .confirmed,                                          // 10
            userId: user.id,
            praxisId: user.praxisId ?? UUID()
               
        )
        Task {
            await viewModel.addAppointment(newAppointment)
        }
        showingAlert = true
    }
}
    
    

#Preview("Appointment Detail") {
    let viewModel = PreviewHelper.createAppointmentViewModel()
    let appointment = PreviewHelper.createSampleAppointments()[0]
    
    return AppointmentDetailView(
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
