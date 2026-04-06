//
//  CompactAppointmentView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 09.02.26.
//
import SwiftUI
import SwiftData
/*
 // MARK: - Compact Appointment View
 struct CompactAppointmentView: View {
     let appointment: Appointment
     
     var body: some View {
         VStack(alignment: .leading, spacing: 4) {
             HStack(spacing: 4) {
                 Image(systemName: "calendar")
                     .font(.caption)
                     .foregroundColor(.accent)
                 Text("Nächster Termin")
                     .font(.caption)
                     .foregroundColor(.secondary)
             }
             HStack(spacing: 12) {
                 Text(appointment.timeString)
                     .font(.title3)
                     .fontWeight(.semibold)
                     .foregroundColor(.primary)

                 VStack(alignment: .leading, spacing: 2) {
                     Text(appointment.therapist)
                         .font(.caption)
                         .foregroundColor(.secondary)
                     Text(appointment.locationName ?? "")
                         .font(.caption)
                         .foregroundColor(.secondary)
                     
                     // ✅ Notizen optional
                                       if let notes = appointment.notes, !notes.isEmpty {
                                           Text(notes)
                                               .font(.caption2)
                                               .foregroundColor(.secondary)
                                               .italic()
                                       }
                 }
                 Spacer()
             }
         }
         .frame(maxWidth: .infinity, alignment: .leading)
     }
 }
 
 */



struct CompactAppointmentView: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.accent)
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
                            .foregroundColor(.accent)
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
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    return CompactAppointmentView(appointment: appointment)
        .padding()
        .background(Color(.systemGray6))
}
