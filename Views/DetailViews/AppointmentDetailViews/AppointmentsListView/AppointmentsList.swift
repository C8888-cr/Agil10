//
//  AppointmentsList.swift
//  Agil10.0
//
//  Created by Christiane Roth on 31.12.25.
//


// Features/Appointments/Presentation/Views/Components/AppointmentsList.swift
import SwiftUI
struct AppointmentsList: View {
    let viewModel: AppointmentViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Next Appointment Card
                if let next = viewModel.nextAppointment {
                    NextAppointmentSection(
                        appointment: next,
                        onDelete: {
                            Task {
                                await viewModel.deleteAppointment(next)
                            }
                        }
                    )
                }
                
                // Upcoming Appointments
                if !viewModel.otherUpcomingAppointments.isEmpty {
                    UpcomingAppointmentsSection(
                        appointments: viewModel.otherUpcomingAppointments,
                        onDelete: { appointment in
                            Task {
                                await viewModel.deleteAppointment(appointment)
                            }
                        }
                    )
                }
                
                // Past Appointments
                if !viewModel.pastAppointments.isEmpty {
                    PastAppointmentsSection(
                        appointments: viewModel.pastAppointments,
                        onDelete: { appointment in
                            Task {
                                await viewModel.deleteAppointment(appointment)
                            }
                        }
                    )
                }
                
                Spacer(minLength: 40)
            }
        }
    }
}
// MARK: - Preview
#Preview {
    AppointmentsList(viewModel: PreviewHelper.createAppointmentViewModel())
}