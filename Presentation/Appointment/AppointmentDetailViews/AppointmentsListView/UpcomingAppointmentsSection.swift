//
//  UpcomingAppointmentsSection.swift
//  Agil10.0
//
//  Created by Christiane Roth on 31.12.25.
//


// Features/Appointments/Presentation/Views/Components/UpcomingAppointmentsSection.swift
import SwiftUI
struct UpcomingAppointmentsSection: View {
    let appointments: [Appointment]
    let onDelete: (Appointment) -> Void
    let onTap: (Appointment) -> Void
    @EnvironmentObject var viewModel: AppointmentViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(themeManager.currentTheme.accentColor)
                Text("Kommende Termine")
                    .font(.headline)
                Spacer()
                Text("\(appointments.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
            }
            
            ForEach(appointments) { appointment in
                AppointmentCardView(
                    appointment: appointment,
                    isNext: false,
                 
                    onDelete: {
                        onDelete(appointment)
                    }
                )
                .onTapGesture { onTap(appointment) }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
}
// MARK: - Preview
#Preview {
    let praxen = PraxisDataManager.shared.praxen

    let appointments = [
        Appointment(
            id: UUID(),
            date: Date().addingTimeInterval(86400),
            therapist: "Dr. Schmidt",
            locationName: praxen[2].name, // agil Langen
            locationAddress: "\(praxen[2].addresse ?? ""), \(praxen[2].postalCode ?? "") \(praxen[2].city ?? "")",
            locationLatitude: praxen[2].latitude,
            locationLongitude: praxen[2].longitude,
            notes: nil,
            emailUID: nil,
            status: .confirmed,
            userId: UUID(),
            therapistId: nil,
            praxisId: praxen[2].id
        ),
        Appointment(
            id: UUID(),
            date: Date().addingTimeInterval(172800),
            therapist: "Dr. Weber",
            locationName: praxen[3].name, // agil Ostend
            locationAddress: "\(praxen[3].addresse ?? ""), \(praxen[3].postalCode ?? "") \(praxen[3].city ?? "")",
            locationLatitude: praxen[3].latitude,
            locationLongitude: praxen[3].longitude,
            notes: nil,
            emailUID: nil,
            status: .confirmed,
            userId: UUID(),
            therapistId: nil,
            praxisId: praxen[3].id
        )
    ]
    
    UpcomingAppointmentsSection(
        appointments: appointments,
        onDelete: { _ in print("Delete tapped") },
        onTap: { _ in print("Tapped") }

    )
    .environmentObject(AppDependencies.shared.appointmentViewModel)
}
