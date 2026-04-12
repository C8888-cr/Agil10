//
//  NextAppointmentSection.swift
//  Agil10.0
//
//  Created by Christiane Roth on 31.12.25.
//


// Features/Appointments/Presentation/Views/Components/NextAppointmentSection.swift
import SwiftUI
struct NextAppointmentSection: View {
    let appointment: Appointment
    let onDelete: () -> Void
    let onTap: () -> Void
    @EnvironmentObject var viewModel: AppointmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Nächster Termin")
                    .font(.headline)
                Spacer()
            }
            
            AppointmentCardView(
                appointment: appointment,
                isNext: true,
                onDelete: onDelete
            )
            .onTapGesture { onTap() }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top)
    }
}
// MARK: - Preview
#Preview {
    let praxis = PraxisDataManager.shared.praxen[1] // agil Preungesheim
    
    let appointment = Appointment(
        id: UUID(),
        date: Date().addingTimeInterval(3600), // in 1 Stunde
        therapist: "Dr. Müller",
        locationName: praxis.name,
        locationAddress: "\(praxis.addresse ?? ""), \(praxis.postalCode ?? "") \(praxis.city ?? "")",
        locationLatitude: praxis.latitude,
        locationLongitude: praxis.longitude,
        notes: "Bitte Handtuch mitbringen",
        emailUID: nil,
        status: .confirmed,
        userId: UUID(),
        therapistId: nil,
        praxisId: praxis.id
    )
    
    NextAppointmentSection(
        appointment: appointment,
        onDelete: { print("Delete tapped") },
        onTap: {  print("Tapped") }
        
    )
    .environmentObject(AppDependencies.shared.appointmentViewModel)
}
