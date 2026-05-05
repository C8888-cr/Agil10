//
//  CompactAppointmentView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 09.02.26.
//
import SwiftUI
import SwiftData

struct CompactAppointmentView: View {
    let appointment: Appointment
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                Text(appointment.isToday ? "Heutiger Termin" : "Nächster Termin")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                if appointment.isToday {
                    Text(appointment.timeString)
                        .font(.title3)
                        .fontWeight(.semibold)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appointment.relativeTimeString)  // "Morgen" / "In 3 Tagen"
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .fontWeight(.semibold)
                        Text(appointment.timeString)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(appointment.therapist)
                        .font(appointment.isToday ? .caption : .caption2)
                        .foregroundColor(.secondary)
                    if let location = appointment.locationName, !location.isEmpty {
                        Text(location)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let notes = appointment.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { onTap() }
                .contentShape(Rectangle())  // ← damit der ganze Bereich tappbar ist
    }
}





#Preview("CompactAppointmentView") {
    let appointment = Appointment(
        id: UUID(),
        date: Date().addingTimeInterval(86400 * 3),
        therapist: "Dr. Schmidt",
        locationName: "Praxis Schmidt",
        locationAddress: "Musterstr. 1, 10115 Berlin",
        locationLatitude: 52.52,
        locationLongitude: 13.40,
        notes: "Physiotherapie Schulter",
        emailUID: "test@example.com",
        status: .confirmed,
        userId: UUID(),
        therapistId: UUID(),
        praxisId: UUID()
    )
    
    return CompactAppointmentView(
        appointment: appointment,
        onTap: { print("Tapped") }
    )
        .padding()
        .background(Color(.systemGray6))
}
