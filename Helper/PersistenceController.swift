//
//  PersistenceController.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  PersistenceController.swift
//  Agil7.0
//
//  Created by Christiane Roth on 07.10.25.
//

// Core/Data/Persistence/PersistenceController.swift
import SwiftData
import Foundation
@MainActor
class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            Appointment.self,
            User.self,
            UserPreferences.self,
            DayGoal.self,
            Video.self , // ✅ Video MUSS hier rein!
            VideoSchedule.self,
            Exercise.self
        ])
        
        // ✅ PERSISTENT Storage (nicht in-memory!)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false  // ✅ WICHTIG!
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: config)
            print("✅ ModelContainer created with PERSISTENT storage")
            print("✅ Schema: \(schema.entities.map { $0.name }.joined(separator: ", "))")
        } catch {
            fatalError("SwiftData Container FAIL: \(error)")
        }
    }
}
