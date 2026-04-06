//
//  AppointmentFilter.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//
import Foundation

// Features/Appointments/Domain/ValueObjects/AppointmentFilter.swift
struct AppointmentFilter {
    private let appointments: [Appointment]
    
    init(_ appointments: [Appointment]) {
        self.appointments = appointments
    }
    
    var nextAppointment: Appointment? {
        upcomingAppointments.first
    }
    
    var upcomingAppointments: [Appointment] {
        appointments
            .filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
    }
    
    var otherUpcomingAppointments: [Appointment] {
        Array(upcomingAppointments.dropFirst())
    }
    
    var pastAppointments: [Appointment] {
        appointments
            .filter { $0.date <= Date() }
            .sorted { $0.date > $1.date }
    }
    
    var highlightedAppointments: [Appointment] {
        appointments.filter { $0.isHighlighted && !$0.wasNotified }
    }
    
    var hasHighlightedAppointments: Bool {
        !highlightedAppointments.isEmpty
    }
    
    func hasAppointment(on date: Date) -> Bool {
        appointments.contains { appointment in
            Calendar.current.isDate(appointment.date, inSameDayAs: date)
        }
    }
    
    func appointment(for date: Date) -> Appointment? {
        appointments.first { appointment in
            Calendar.current.isDate(appointment.date, inSameDayAs: date)
        }
    }
}
