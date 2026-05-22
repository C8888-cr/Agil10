// Features/Appointments/Presentation/Views/AppointmentDetailView.swift
import SwiftUI
import MapKit
import SwiftData


struct AppointmentDetailView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let appointment: Appointment
    @EnvironmentObject var viewModel: AppointmentViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showingCancelSheet = false
    
    // MARK: - Section Edit States
    @State private var isEditingTime = false
    @State private var isEditingDuration = false
    @State private var isEditingTherapist = false
    @State private var isEditingNotes = false
    
    // MARK: - Temporäre Edit-Werte
    @State private var editedDate = Date()
    @State private var editedTime = Date()
    @State private var editedDuration = 20
    @State private var editedTherapistId: UUID? = nil
    @State private var editedTherapistName = ""
    @State private var isManualTherapist = false
    @State private var editedNotes = ""
    
    private let durations = [20, 30, 40, 50, 60, 70, 80, 90]
    private let manualTherapistId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    
    private var accent: Color { themeManager.currentTheme.accentColor }
    
    private var availableTherapists: [Therapeut] {
        guard let praxisId = session.currentUser?.praxisId else { return [] }
        return TherapeutDataManager.shared.getTherapeutenForPraxis(praxisId)
    }
    
    private var endDate: Date {
        appointment.date.addingTimeInterval(TimeInterval(appointment.durationMinutes * 60))
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
    
    private var isEditable: Bool {
        appointment.status != .cancelled && !appointment.isPast
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        timeCard
                        durationCard
                        therapistCard
                        notesCard
                        locationCard
                        statusCard
                        cancelButton
                        Spacer(minLength: 20)
                    }
                    .padding(.top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingCancelSheet) {
                CancelAppointmentView(
                    appointment: appointment,
                    isPresented: $showingCancelSheet
                )
                .environmentObject(session)
                .environmentObject(viewModel)
            }
        }
    }
    
    // MARK: - Header (Avatar-Stil wie ProfileHeaderCard)
    private var headerCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(accent)
            
            VStack(spacing: 4) {
                Text(appointment.formattedDate)
                    .font(.title2.bold())
                
                Text("\(appointment.date.formatted(date: .omitted, time: .shortened)) – \(endDate.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Zeit
    private var timeCard: some View {
        InfoCard {
            sectionHeader(label: "Termin", icon: "clock", isEditing: isEditingTime) {
                if isEditingTime {
                    saveTime()
                } else {
                    editedDate = appointment.date
                    editedTime = appointment.date
                    isEditingTime = true
                }
            }
            
            if isEditingTime {
                DatePicker("Datum", selection: $editedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                DatePicker("Uhrzeit", selection: $editedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
            } else {
                HStack {
                    Text("").foregroundStyle(.secondary)
                    Spacer()
                    Text(appointment.date.formatted(date: .omitted, time: .shortened))
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    // MARK: - Dauer
    private var durationCard: some View {
        InfoCard {
            sectionHeader(label: "Dauer", icon: "hourglass", isEditing: isEditingDuration) {
                if isEditingDuration {
                    saveDuration()
                } else {
                    editedDuration = appointment.durationMinutes
                    isEditingDuration = true
                }
            }
            
            if isEditingDuration {
                Picker("Dauer", selection: $editedDuration) {
                    ForEach(durations, id: \.self) { min in
                        Text("\(min) Minuten").tag(min)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack {
                    Text("").foregroundStyle(.secondary)
                    Spacer()
                    Text("\(appointment.durationMinutes) Minuten")
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    // MARK: - Therapeut
    private var therapistCard: some View {
        InfoCard {
            sectionHeader(label: "Therapeut", icon: "person.fill", isEditing: isEditingTherapist) {
                if isEditingTherapist {
                    saveTherapist()
                } else {
                    startEditingTherapist()
                }
            }
            
            if isEditingTherapist {
                Picker("Therapeut", selection: $editedTherapistId) {
                    Text("Kein Therapeut").tag(nil as UUID?)
                    ForEach(availableTherapists) { t in
                        Text(t.fullName).tag(t.id as UUID?)
                    }
                    Text("Manuell eintragen").tag(manualTherapistId)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: editedTherapistId) { _, newId in
                    if newId == manualTherapistId {
                        isManualTherapist = true
                        editedTherapistName = ""
                    } else if let id = newId,
                              let t = availableTherapists.first(where: { $0.id == id }) {
                        isManualTherapist = false
                        editedTherapistName = t.fullName
                    } else {
                        isManualTherapist = false
                        editedTherapistName = ""
                    }
                }
                
                if isManualTherapist {
                    TextField("Name des Therapeuten", text: $editedTherapistName)
                        .textContentType(.name)
                }
            } else {
                HStack {
                    Text("").foregroundStyle(.secondary)
                    Spacer()
                    Text(appointment.therapist ?? "Nicht angegeben")
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    // MARK: - Notizen
    private var notesCard: some View {
        InfoCard {
            sectionHeader(label: "Notizen", icon: "note.text", isEditing: isEditingNotes) {
                if isEditingNotes {
                    saveNotes()
                } else {
                    editedNotes = appointment.notes ?? ""
                    isEditingNotes = true
                }
            }
            
            if isEditingNotes {
                TextEditor(text: $editedNotes)
                    .frame(minHeight: 80)
                    .padding(4)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(8)
            } else if let notes = appointment.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Keine Notizen")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Location (nur Anzeige)
    @ViewBuilder
    private var locationCard: some View {
        if appointment.locationName != nil || appointment.locationAddress != nil {
            InfoCard {
                LocationSection(
                    appointment: appointment,
                    showMap: appointment.coordinate != nil,
                    region: region
                )
            }
        }
    }
    
    // MARK: - Status (nur wenn abgesagt)
    @ViewBuilder
    private var statusCard: some View {
        if appointment.status == .cancelled {
            InfoCard {
                HStack {
                    Label {
                        Text("Status").foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(accent.opacity(0.7))
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(appointment.status.color)
                            .frame(width: 10, height: 10)
                        Text(appointment.status.displayName)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
    
    // MARK: - Absagen Button (dezent rot)
    @ViewBuilder
    private var cancelButton: some View {
        if appointment.status != .cancelled {
            Button {
                showingCancelSheet = true
            } label: {
                Label("Termin absagen", systemImage: "xmark.circle")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                    )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Section Header (Label + Edit-Stift)
    private func sectionHeader(
        label: String,
        icon: String,
        isEditing: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Label {
                Text(label).foregroundStyle(.secondary)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(accent.opacity(0.7))
            }
            Spacer()
            if isEditable {
                Button(action: action) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                        .foregroundColor(accent)
                        .font(.title3)
                }
            }
        }
    }
    
    // MARK: - Therapeut Edit Start
    private func startEditingTherapist() {
        let name = appointment.therapist ?? ""
        editedTherapistName = name
        if name.isEmpty {
            editedTherapistId = nil
            isManualTherapist = false
        } else if let match = availableTherapists.first(where: { $0.fullName == name }) {
            editedTherapistId = match.id
            isManualTherapist = false
        } else {
            editedTherapistId = manualTherapistId
            isManualTherapist = true
        }
        isEditingTherapist = true
    }
    
    // MARK: - Save Helpers (alle über viewModel.updateAppointment)
    private func saveTime() {
        let cal = Calendar.current
        let d = cal.dateComponents([.year, .month, .day], from: editedDate)
        let t = cal.dateComponents([.hour, .minute], from: editedTime)
        var c = DateComponents()
        c.year = d.year; c.month = d.month; c.day = d.day
        c.hour = t.hour; c.minute = t.minute
        guard let finalDate = cal.date(from: c) else { return }
        
        persist(date: finalDate)
        isEditingTime = false
    }
    
    private func saveDuration() {
        persist(durationMinutes: editedDuration)
        isEditingDuration = false
    }
    
    private func saveTherapist() {
        let clean = editedTherapistName.trimmingCharacters(in: .whitespaces)
        persist(therapist: clean.isEmpty ? nil : clean)
        isEditingTherapist = false
    }
    
    private func saveNotes() {
        persist(notes: editedNotes.isEmpty ? nil : editedNotes)
        isEditingNotes = false
    }
    
    /// Zentraler Speicher-Weg — identisch zu ManualAppointmentEntryView.
    /// Nicht gesetzte Parameter behalten den aktuellen Wert des Termins.
    private func persist(
        date: Date? = nil,
        therapist: String?? = nil,
        durationMinutes: Int? = nil,
        notes: String?? = nil
    ) {
        Task {
            await viewModel.updateAppointment(
                appointment,
                date: date ?? appointment.date,
                therapist: therapist ?? appointment.therapist,
                locationName: appointment.locationName,
                locationAddress: appointment.locationAddress,
                latitude: appointment.locationLatitude,
                longitude: appointment.locationLongitude,
                notes: notes ?? appointment.notes,
                durationMinutes: durationMinutes ?? appointment.durationMinutes
            )
        }
    }
}
