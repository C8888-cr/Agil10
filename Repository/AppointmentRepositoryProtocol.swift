//
//  AppointmentRepositoryProtocol.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  AppointmentRepository.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//

// Features/Appointments/Services/AppointmentRepository.swift
import Foundation
import SwiftData
protocol AppointmentRepositoryProtocol {
    func fetchAll() throws -> [Appointment]
    func fetchUpcoming() throws -> [Appointment]
    func fetchPast() throws -> [Appointment]
    func fetchHighlighted() throws -> [Appointment]
    func save(_ appointment: Appointment) throws
    func delete(_ appointment: Appointment) throws
    func checkDuplicate(date: Date, therapist: String) throws -> Bool
  
}
class AppointmentRepository: AppointmentRepositoryProtocol {
    private let modelContext: ModelContext
    private let userId: UUID
    
    init(modelContext: ModelContext, userId: UUID) {
        self.modelContext = modelContext
        self.userId = userId
    }

    
    
    func fetchAll() throws -> [Appointment] {
        let descriptor = FetchDescriptor<Appointment>(
            sortBy: [SortDescriptor(\.date)]
        )
        
        let allAppointments = try self.modelContext.fetch(descriptor)
        // 🔍 DEBUG
        print("📦 Total Appointments in DB: \(allAppointments.count)")
        print("👤 Filtering for userId: \(self.userId)")
        
        for apt in allAppointments {
               print("   → \(apt.therapist) | userId: \(apt.userId?.uuidString ?? "NIL") | date: \(apt.date)")
           }
           
           let filtered = allAppointments.filter { $0.userId == self.userId }
           print("✅ Filtered result: \(filtered.count)")
           
           return filtered
       }



    func fetchUpcoming() throws -> [Appointment] {
        let now = Date()
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate { $0.date > now },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPast() throws -> [Appointment] {
        let now = Date()
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate { $0.date <= now },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchHighlighted() throws -> [Appointment] {
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate { $0.isHighlighted == true && $0.wasNotified == false }
        )
        return try modelContext.fetch(descriptor)
    }
    
    
    
    func save(_ appointment: Appointment) throws {
        
        print("💾 Saving appointment:")
        print("   → Therapist: \(appointment.therapist)")
        print("   → userId: \(appointment.userId?.uuidString ?? "❌ NIL")")
        print("   → Date: \(appointment.date)")
        
        
        modelContext.insert(appointment)
        try modelContext.save()
        
        print("✅ Saved successfully")
    }
    
    func delete(_ appointment: Appointment) throws {
        modelContext.delete(appointment)
        try modelContext.save()
    }
    
    func checkDuplicate(date: Date, therapist: String) throws -> Bool {
        let appointments = try fetchAll()
        return appointments.contains { existing in
            Calendar.current.isDate(existing.date, inSameDayAs: date) &&
            existing.therapist == therapist
        }
    }
}
