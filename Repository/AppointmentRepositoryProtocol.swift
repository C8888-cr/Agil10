//
//  AppointmentRepository.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//
import Foundation
import SwiftData
// MARK: - Protocol
@MainActor
protocol AppointmentRepositoryProtocol {
    func fetchAll() throws -> [Appointment]
    func fetchUpcoming() throws -> [Appointment]
    func fetchPast() throws -> [Appointment]
    func fetchHighlighted() throws -> [Appointment]
    func save(_ appointment: Appointment) throws
    func delete(_ appointment: Appointment) throws
    func checkDuplicate(date: Date, therapist: String) throws -> Bool
}
// MARK: - Repository
@MainActor
class AppointmentRepository: AppointmentRepositoryProtocol {
    private let modelContext: ModelContext
    private weak var authService: AuthService?
    
    // ✅ KORRIGIERT: authService statt userId übergeben
    init(modelContext: ModelContext, authService: AuthService) {
        self.modelContext = modelContext
        self.authService = authService
    }
    
    // ✅ Computed Property für aktuelle userId
    private var currentUserId: UUID? {
        authService?.currentUser?.id
    }
    
    // MARK: - Fetch Methods
    
    func fetchAll() throws -> [Appointment] {
        guard let userId = currentUserId else {
            print("⚠️ fetchAll: Kein User eingeloggt")
            return []
        }
        
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate { $0.userId == userId }
        )
        let appointments = try modelContext.fetch(descriptor)
        print("✅ Loaded \(appointments.count) appointments for user \(userId)")
        return appointments
    }
    
    func fetchUpcoming() throws -> [Appointment] {
        guard let userId = currentUserId else {
            print("⚠️ fetchUpcoming: Kein User eingeloggt")
            return []
        }
        
        let now = Date()
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate {
                $0.userId == userId && $0.date > now  // ✅ userId-Filter hinzugefügt
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPast() throws -> [Appointment] {
        guard let userId = currentUserId else {
            print("⚠️ fetchPast: Kein User eingeloggt")
            return []
        }
        
        let now = Date()
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate {
                $0.userId == userId && $0.date <= now  // ✅ userId-Filter
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchHighlighted() throws -> [Appointment] {
        guard let userId = currentUserId else {
            print("⚠️ fetchHighlighted: Kein User eingeloggt")
            return []
        }
        
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate {
                $0.userId == userId &&           // ✅ userId-Filter
                $0.isHighlighted == true &&
                $0.wasNotified == false
            }
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Save/Delete
    
    func save(_ appointment: Appointment) throws {
        guard let userId = currentUserId else {
            throw AppointmentError.notFound  // ⚠️ Besserer Error: .noUserLoggedIn
        }
        
        print("💾 Saving appointment:")
        print("   → Therapist: \(appointment.therapist)")
        print("   → Date: \(appointment.date)")
        
        // ✅ userId setzen
        appointment.userId = userId
        
        modelContext.insert(appointment)
        try modelContext.save()
        
        print("✅ Saved with userId: \(userId)")
    }
    
    func delete(_ appointment: Appointment) throws {
        modelContext.delete(appointment)
        try modelContext.save()
        print("🗑️ Deleted appointment: \(appointment.therapist)")
    }
    
    // MARK: - Duplicate Check
    
    func checkDuplicate(date: Date, therapist: String) throws -> Bool {
        let appointments = try fetchAll()  // ✅ Nutzt fetchAll (filtered nach userId)
        
        let isDuplicate = appointments.contains { existing in
            Calendar.current.isDate(existing.date, inSameDayAs: date) &&
            existing.therapist == therapist
        }
        
        if isDuplicate {
            print("⚠️ Duplicate found: \(therapist) on \(date)")
        }
        
        return isDuplicate
    }
}
