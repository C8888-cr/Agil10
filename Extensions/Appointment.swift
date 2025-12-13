//
//  Appointment.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//

//
//  Extensions.swift
//  Agil7.0
//
//  Created by Christiane Roth on 07.10.25.
//

// Features/Appointments/Domain/Models/Appointment+Extensions.swift
import Foundation
extension Appointment {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
}
