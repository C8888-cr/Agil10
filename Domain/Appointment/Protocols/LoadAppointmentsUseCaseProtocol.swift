//
//  LoadAppointmentsUseCaseProtocol.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


import Foundation
protocol LoadAppointmentsUseCaseProtocol {
    func execute(for user: User) async throws -> [Appointment]
}
