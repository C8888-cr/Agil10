

import SwiftUI
import SwiftData
// MARK: - AppointmentCardView mit Maps-Integration
struct AppointmentCardView: View {
    
    let appointment: Appointment
    let isNext: Bool
    let onDelete: (() -> Void)?
    let onCancel: ((String?) -> Void)?
    @EnvironmentObject var authService: AuthService
    @Environment(\.modelContext) var modelContext
    
    
    @State private var showingDeleteAlert = false
    @State private var showingCancelSheet = false      // ← NEU
    
    @State private var isCancelling = false            // ← NEU
    @State private var showingCancelError = false      // ← NEU
    @State private var cancelErrorMessage = ""         // ← NEU
    @EnvironmentObject var viewModel: AppointmentViewModel
    
    
    init(
        appointment: Appointment,
        isNext: Bool,
       // ← NEU
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
                .fill(appointment.status == .cancelled ? Color.red.opacity(0.5) : isNext ? Color.accent : Color.secondary.opacity(0.5))
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
                        .foregroundColor(.accent)
                    Text(appointment.therapist)
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
                    .foregroundColor(.accent)
                }
            
            
  
                  }
            
            Spacer()
            
            // Maps Button
            if appointment.coordinate != nil {
                Button(action: {
                    appointment.openInMaps()
                }) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accent)
                }
                .buttonStyle(.plain)
            }
            
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
            .environmentObject(authService)
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
