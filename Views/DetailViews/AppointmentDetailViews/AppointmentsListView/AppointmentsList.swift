//
//  AppointmentsList.swift
//  Agil10.0
//
//  Created by Christiane Roth on 31.12.25.
//


// Features/Appointments/Presentation/Views/Components/AppointmentsList.swift
import SwiftUI
struct AppointmentsList: View {
    
    let appointments: [Appointment]  // ✅ Parameter statt ViewModel
       @ObservedObject var viewModel: AppointmentViewModel

    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // ✅ Next Appointment Card
                             if let next = viewModel.nextAppointment(from: appointments) {
                                 NextAppointmentSection(
                                     appointment: next,
                                     onDelete: {
                                         Task {
                                             await viewModel.deleteAppointment(next)
                                         }
                                     },
                                     viewModel: viewModel
                                 )
                             }
                
                // ✅ Upcoming Appointments
                            let otherUpcoming = viewModel.otherUpcomingAppointments(from: appointments)
                            if !otherUpcoming.isEmpty {
                                UpcomingAppointmentsSection(
                                    appointments: otherUpcoming,
                                    onDelete: { appointment in
                                        Task {
                                            await viewModel.deleteAppointment(appointment)
                                        }
                                       
                                    },
                                    viewModel: viewModel
                                )
                            }
                
                // ✅ Past Appointments
                             let past = viewModel.pastAppointments(from: appointments)
                             if !past.isEmpty {
                                 PastAppointmentsSection(
                                     appointments: past,
                                     onDelete: { appointment in
                                         Task {
                                             await viewModel.deleteAppointment(appointment)
                                         }
                                     },
                                     viewModel: viewModel
                                 )
                             }
                             
                
                Spacer(minLength: 40)
            }
        }
    }
}
// MARK: - Preview
// MARK: - Preview
#Preview {
    let container = PreviewHelper.createModelContainer()
    let viewModel = PreviewHelper.createAppointmentViewModel()
    
    // ✅ Mock User ID
    let mockUserId = UUID()
    let mockPraxisId = UUID()
    
    // ✅ Mock appointments mit allen required Parametern
    let mockAppointments = [
        Appointment(
            date: Date().addingTimeInterval(3600),
            therapist: "Dr. Müller",
            locationName: "Praxis A", locationAddress: "Hauptstraße 1, 12345 Berlin", userId: mockUserId,           // ✅ NEU
            praxisId: mockPraxisId
        ),
        Appointment(
            date: Date().addingTimeInterval(86400),
            therapist: "Dr. Schmidt",
            locationName: "Praxis B", locationAddress: "Nebenstraße 2, 12345 Berlin", userId: mockUserId,           // ✅ NEU
            praxisId: mockPraxisId
        )
    ]
    
    AppointmentsList(
        appointments: mockAppointments,
        viewModel: viewModel
    )
    .modelContainer(container)
}
