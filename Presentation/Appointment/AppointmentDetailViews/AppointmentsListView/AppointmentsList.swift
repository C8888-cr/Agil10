//
//  AppointmentsList.swift
//  Agil10.0
//
//  Created by Christiane Roth on 31.12.25.

import SwiftUI


struct AppointmentsList: View {
    
    let appointments: [Appointment]
    @ObservedObject var viewModel: AppointmentViewModel
    @State private var selectedAppointment: Appointment? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // ✅ Next Appointment Card
                if let next = viewModel.nextAppointment(from: appointments) {
                                  NextAppointmentSection(
                                      appointment: next,
                                      onDelete: {
                                          Task { await viewModel.deleteAppointment(next)
                                          }
                                      },
                                      onTap: { selectedAppointment = next }
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
                                    onTap: { selectedAppointment = $0 }
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
                                     onTap: { selectedAppointment = $0 }
                                 )
                             }
                             
                
                Spacer(minLength: 40)
            }
        }
        .sheet(item: $selectedAppointment) { appointment in  // ← NEU
                    AppointmentDetailView(appointment: appointment)
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
