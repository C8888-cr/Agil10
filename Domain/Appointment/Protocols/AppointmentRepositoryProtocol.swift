//
//  AppointmentRepositoryProtocol.swift
//  Agil10.0
//
//  Created by Christiane Roth on 23.03.26.
//


import Foundation

// MARK: - Protocol
@MainActor
protocol AppointmentRepositoryProtocol {
    func fetchAll() async throws -> [Appointment]
    func fetchUpcoming() async throws -> [Appointment]
    func fetchPast() async throws -> [Appointment]
    func fetchHighlighted() async throws -> [Appointment]
    func save(_ appointment: Appointment) async throws
    func delete(_ appointment: Appointment) async throws
    func checkDuplicate(date: Date, therapist: String) async throws -> Bool
    func saveContext() async throws
}
