//
//  AppointmentCardView.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


/*
import SwiftUI
// MARK: - Appointment Card
struct AppointmentCardView: View {
   
    let appointment: Appointment
    let isNext: Bool
    let onDelete: (() -> Void)?
    
    @State private var showingDeleteAlert = false
    
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 4)
                .fill(isNext ? Color.primaryAccent : Color.secondary.opacity(0.5))
                .frame(width: 4, height: 70)
            // Date Badge
            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Text(appointment.date.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.formattedTime)
                    .font(.headline)
                
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.primaryAccent)
                    Text(appointment.therapist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let location = appointment.locationName {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundColor(.accent)
                }
            }
            
            
            
            Spacer()
            
            // Actions
            Menu {
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
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .alert("Termin löschen?", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                onDelete?()  // ✅ Callback aufrufen
            }
        } message: {
            Text("Möchtest du diesen Termin wirklich löschen?")
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
                locationName: "Praxis Zentrum"
            ),
            isNext: true,
            onDelete: { print("Termin gelöscht") }
        )
        
        AppointmentCardView(
            appointment: Appointment(
                date: Date().addingTimeInterval(86400),
                therapist: "Dr. Schmidt",
                locationName: nil
            ),
            isNext: false,
            onDelete: { print("Termin gelöscht") }
        )
    }
    .padding()
}
*/
import SwiftUI
import SwiftData

// MARK: - AppointmentCardView mit Maps-Integration
struct AppointmentCardView: View {
   
    let appointment: Appointment
    let isNext: Bool
    let onDelete: (() -> Void)?
    
    @State private var showingDeleteAlert = false
    
    init(
        appointment: Appointment,
        isNext: Bool,
        onDelete: (() -> Void)? = nil
    ) {
        self.appointment = appointment
        self.isNext = isNext
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 4)
                .fill(isNext ? Color.accent : Color.secondary.opacity(0.5))
                .frame(width: 4, height: 70)
            
            // Date Badge
            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Text(appointment.date.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.formattedTime)
                    .font(.headline)
                
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.accent)
                    Text(appointment.therapist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let location = appointment.locationName {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundColor(.accent)
                }
            }
            
            Spacer()
            
            // ✅ Navigation Button (nutzt appointment.openInMaps())
            if appointment.coordinate != nil {
                Button(action: {
                    appointment.openInMaps()  // ✅ Direkt die Extension nutzen!
                }) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accent)
                }
                .buttonStyle(.plain)
            }
            
            // Actions Menu
            Menu {
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
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .alert("Termin löschen?", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Möchtest du diesen Termin wirklich löschen?")
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
