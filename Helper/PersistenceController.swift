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
            User.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: config
            )
        } catch {
            fatalError("❌ Failed to create ModelContainer: \(error)")
        }
    }
}
