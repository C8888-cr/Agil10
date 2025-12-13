//
//  ParseAppointmentsFromEmailUseCaseProtocol.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


import Foundation
import SwiftData
// MARK: - Protocol (für Dependency Injection)
protocol ParseAppointmentsFromEmailUseCaseProtocol {
    func execute(emailText: String) async throws -> AppointmentChanges
}