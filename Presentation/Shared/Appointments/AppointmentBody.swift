//
//  AppointmentBody.swift
//  Agil10.0
//
//  Created by Christiane Roth on 23.05.26.
//


//  AppointmentBody.swift
//  Agil10.0
//
//  Reines Inhaltslayout eines Termins (Balken, Datum, Infos).
//  Ohne Verhalten – wiederverwendbar in Cards und Listen.

import SwiftUI
import AgilCore


struct AppointmentBody: View {
    let appointment: Appointment
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 4)
                .fill(themeManager.currentTheme.accentColor)
                .frame(width: 4)

            dateBadge

            infoColumn

            Spacer()
        }
    }

    // MARK: - Datum-Badge
    private var dateBadge: some View {
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
    }

    // MARK: - Info-Spalte
    private var infoColumn: some View {
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
    }
}

#Preview {
    AppointmentBody(
        appointment: Appointment(
            date: Date(),
            therapist: "Dr. Müller",
            locationName: "Praxis Zentrum",
            notes: "Kontrolltermin",
            userId: UUID(),
            praxisId: UUID()
        )
    )
    .glassCard()
    .padding()
    .environmentObject(ThemeManager())
}
