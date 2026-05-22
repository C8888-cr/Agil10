/*

import SwiftUI
import SwiftData
// MARK: - AppointmentCardView mit Maps-Integration
struct AppointmentCardView: View {
    
    let appointment: Appointment
    let isNext: Bool
    let onDelete: (() -> Void)?
    let onCancel: ((String?) -> Void)?
    @EnvironmentObject var session: SessionManager
    @Environment(\.modelContext) var modelContext
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingCancelSheet = false      // ← NEU
    
    @State private var isCancelling = false            // ← NEU
    @State private var showingCancelError = false      // ← NEU
    @State private var cancelErrorMessage = ""         // ← NEU
    @EnvironmentObject var viewModel: AppointmentViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    init(
        appointment: Appointment,
        isNext: Bool,
        onDelete: (() -> Void)? = nil,
        onCancel: ((String?) -> Void)? = nil
    ) {
        self.appointment = appointment
        self.isNext = isNext

        self.onDelete = onDelete
        self.onCancel = onCancel
    }
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 4)
                .fill(appointment.status == .cancelled
                      ? Color.red.opacity(0.5)
                        : isNext
                            ? themeManager.currentTheme.accentColor
                            : Color.secondary.opacity(0.5))
                    .frame(width: 4)
            
            // Date Badge
            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(appointment.date.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(width: 35)
            
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.formattedTime)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    Text(appointment.therapist ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                if let location = appointment.locationName {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(location)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            
                //Notizen
                    if let notes = appointment.notes {
                        HStack(spacing: 4) {
                            Image(systemName: "note.text")
                                .font(.caption)
                            Text(notes)
                                .font(.caption)
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }
                        .foregroundColor(.secondary)
                    }
  
                  }
            
            Spacer()

            
            // MARK: - Actions Menu
            Menu {
                // ✅ Absagen (nur wenn noch nicht abgesagt)
                if appointment.status != .cancelled && !appointment.isPast {
                    Button(action: {
                        showingCancelSheet = true
                    }) {
                        Label("Termin absagen", systemImage: "xmark.circle")
                    }
                }
                
                // 🆕 Bearbeiten (nur wenn nicht abgesagt und nicht in Vergangenheit)
                    if appointment.status != .cancelled && !appointment.isPast {
                        Button(action: {
                            showingEditSheet = true
                        }) {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                    }
                
                Divider()
                
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    Label("Löschen", systemImage: "trash")
                }
                
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }
        .dynamicTypeSize(.small ... .large)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(alignment: .bottomTrailing) {  // ← NEU
            if appointment.status == .cancelled {
                Text("Abgesagt")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red)
                    .cornerRadius(6)
                    .padding(8)
            }
        }
        
        // MARK: - Delete Alert
        .alert("Termin löschen?", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Möchtest du diesen Termin wirklich löschen?")
        }
        
        // MARK: - Cancel Error Alert
        .alert("Fehler", isPresented: $showingCancelError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(cancelErrorMessage)
        }
        
        // MARK: - Cancel Sheet
        .sheet(isPresented: $showingCancelSheet) {
            CancelAppointmentView(
                appointment: appointment,
         
                isPresented: $showingCancelSheet
            )
            .environmentObject(session)
        }
        .sheet(isPresented: $showingEditSheet) {           // 🆕
            ManualAppointmentEntryView(appointmentToEdit: appointment)
        }
           }
       }


// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        // Mit Location (zeigt Maps-Button)
        AppointmentCardView(
            appointment: Appointment(
                date: Date(),
                therapist: "Dr. Müller",
                locationName: "Praxis Zentrum",
                locationAddress: "Hauptstraße 42, 10115 Berlin",
                locationLatitude: 52.520008,
                locationLongitude: 13.404954,
                userId: UUID(),        // ✅ Mock UUID
                praxisId: UUID()
            ),
            isNext: true,
            onDelete: { print("Termin gelöscht") }
        )
        
        // Ohne Location (kein Maps-Button)
        AppointmentCardView(
            appointment: Appointment(
                date: Date().addingTimeInterval(86400),
                therapist: "Dr. Schmidt",
                locationName: nil,
                userId: UUID(),        // ✅ Mock UUID
                praxisId: UUID()
            ),
            isNext: false,
            onDelete: { print("Termin gelöscht") }
        )
    }
    .padding()
}
*/

// neu mit Swipe:

import SwiftUI
import SwiftData

// MARK: - AppointmentCardView mit Maps-Integration
struct AppointmentCardView: View {
    
    let appointment: Appointment
    let isNext: Bool
    let onDelete: (() -> Void)?
    let onCancel: ((String?) -> Void)?
    @EnvironmentObject var session: SessionManager
    @Environment(\.modelContext) var modelContext
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingCancelSheet = false
    
    @State private var isCancelling = false
    @State private var showingCancelError = false
    @State private var cancelErrorMessage = ""
    @EnvironmentObject var viewModel: AppointmentViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Swipe State
    @State private var offset: CGFloat = 0
    @State private var dragDirection: DragDirection? = nil
    @State private var hasTriggeredHaptic = false
    
    private enum DragDirection { case horizontal, vertical }
    
    // Swipe-Konstanten (konsistent mit der Video-Row)
    private let actionAreaWidth: CGFloat = 80
    private let deleteThreshold: CGFloat = 120
    
    init(
        appointment: Appointment,
        isNext: Bool,
        onDelete: (() -> Void)? = nil,
        onCancel: ((String?) -> Void)? = nil
    ) {
        self.appointment = appointment
        self.isNext = isNext
        self.onDelete = onDelete
        self.onCancel = onCancel
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            
            // MARK: - Lösch-Bereich (hinter der Card)
            if offset < 0 {
                deleteBackground
            }
            
            // MARK: - Card-Inhalt (verschiebbar)
            cardContent
                .offset(x: offset)
                .simultaneousGesture(dragGesture)
        }
        .animation(.spring(response: 0.3), value: offset)
        
        // MARK: - Delete Alert
        .alert("Termin löschen?", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) {
                close()
            }
            Button("Löschen", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Möchtest du diesen Termin wirklich löschen?")
        }
        
        // MARK: - Cancel Error Alert
        .alert("Fehler", isPresented: $showingCancelError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(cancelErrorMessage)
        }
        
        // MARK: - Cancel Sheet
        .sheet(isPresented: $showingCancelSheet) {
            CancelAppointmentView(
                appointment: appointment,
                isPresented: $showingCancelSheet
            )
            .environmentObject(session)
            .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingEditSheet) {
            ManualAppointmentEntryView(appointmentToEdit: appointment)
        }
    }
    
    // MARK: - Card Content
    private var cardContent: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 4)
                .fill(appointment.status == .cancelled
                      ? Color.red.opacity(0.5)
                        : isNext
                            ? themeManager.currentTheme.accentColor
                            : Color.secondary.opacity(0.5))
                    .frame(width: 4)
            
            // Date Badge
            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(appointment.date.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(width: 35)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.formattedTime)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    Text(appointment.therapist ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                if let location = appointment.locationName {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(location)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            
                // Notizen
                if let notes = appointment.notes {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.caption)
                        Text(notes)
                            .font(.caption)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // MARK: - Actions Menu (ohne Löschen — das geht jetzt per Swipe)
            Menu {
                // ✅ Absagen (nur wenn noch nicht abgesagt)
                if appointment.status != .cancelled && !appointment.isPast {
                    Button(action: {
                        showingCancelSheet = true
                    }) {
                        Label("Termin absagen", systemImage: "xmark.circle")
                    }
                }
                
                // 🆕 Bearbeiten (nur wenn nicht abgesagt und nicht in Vergangenheit)
                if appointment.status != .cancelled && !appointment.isPast {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                }
                
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }
        .dynamicTypeSize(.small ... .large)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(alignment: .bottomTrailing) {
            if appointment.status == .cancelled {
                Text("Abgesagt")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red)
                    .cornerRadius(6)
                    .padding(8)
            }
        }
    }
    
    // MARK: - Delete Background
    private var deleteBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.red)
            .overlay(
                Image(systemName: "trash.fill")
                    .foregroundColor(.white)
                    .font(.title3)
                    .padding(.trailing, (actionAreaWidth - 24) / 2),
                alignment: .trailing
            )
    }
    
    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                if dragDirection == nil {
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)
                    if dx > dy && dx > 10 {
                        dragDirection = .horizontal
                    } else if dy > dx {
                                            dragDirection = .vertical
                                            if offset != 0 {
                                                close()
                                            }
                                            return
                                        }
                }
                
                guard dragDirection == .horizontal else { return }
                
                let drag = value.translation.width
                
                if drag < 0 {
                    offset = max(drag, -500)
                    
                    let triggered = abs(offset) >= deleteThreshold
                    if triggered != hasTriggeredHaptic {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        hasTriggeredHaptic = triggered
                    }
                } else {
                    offset = min(drag, 0)
                }
            }
            .onEnded { value in
                defer {
                    dragDirection = nil
                    hasTriggeredHaptic = false
                }
                guard dragDirection == .horizontal else { return }
                
                // Über Threshold → Löschen bestätigen
                if abs(offset) >= deleteThreshold {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    withAnimation(.spring(response: 0.3)) {
                        offset = -actionAreaWidth
                    }
                    showingDeleteAlert = true
                    return
                }
                
                withAnimation(.spring(response: 0.3)) {
                    if abs(offset) > actionAreaWidth / 2 {
                        offset = -actionAreaWidth
                    } else {
                        close()
                    }
                }
            }
    }
    
    // MARK: - Helpers
    private func close() {
        withAnimation(.spring(response: 0.3)) {
            offset = 0
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        AppointmentCardView(
            appointment: Appointment(
                date: Date(),
                therapist: "Dr. Müller",
                locationName: "Praxis Zentrum",
                locationAddress: "Hauptstraße 42, 10115 Berlin",
                locationLatitude: 52.520008,
                locationLongitude: 13.404954,
                userId: UUID(),
                praxisId: UUID()
            ),
            isNext: true,
            onDelete: { print("Termin gelöscht") }
        )
        
        AppointmentCardView(
            appointment: Appointment(
                date: Date().addingTimeInterval(86400),
                therapist: "Dr. Schmidt",
                locationName: nil,
                userId: UUID(),
                praxisId: UUID()
            ),
            isNext: false,
            onDelete: { print("Termin gelöscht") }
        )
    }
    .padding()
}
