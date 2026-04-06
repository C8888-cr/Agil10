//
//  PastAppointmentsSection.swift
//  Agil10.0
//
//  Created by Christiane Roth on 31.12.25.
//


// Features/Appointments/Presentation/Views/Components/PastAppointmentsSection.swift
import SwiftUI
struct PastAppointmentsSection: View {
    let appointments: [Appointment]
    let onDelete: (Appointment) -> Void
    @EnvironmentObject var viewModel: AppointmentViewModel
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.secondary)
                Text("Vergangene Termine")
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
                .opacity(0.6)
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
    let praxis = PraxisDataManager.shared.praxen[0] // agil Eschersheim
    
    let appointments = [
        Appointment(
            id: UUID(),
            date: Date().addingTimeInterval(-86400),
            therapist: "Dr. Klein",
            locationName: praxis.name,
            locationAddress: "\(praxis.addresse ?? ""), \(praxis.postalCode ?? "") \(praxis.city ?? "")",
            locationLatitude: praxis.latitude,
            locationLongitude: praxis.longitude,
            notes: nil,
            emailUID: nil,
            status: .confirmed,
            userId: UUID(),
            therapistId: nil,
            praxisId: praxis.id
        )
    ]
    
    PastAppointmentsSection(
        appointments: appointments,
        onDelete: { _ in print("Delete tapped") }
    )
    .environmentObject(AppDependencies.shared.appointmentViewModel)
}
