//
//  AgilKGGApp.swift
//  AgilKGG
//
//  Created by Christiane Roth on 24.06.26.
//

import SwiftUI
import SwiftData
import AgilCore

@main
struct AgilKGGApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: KGGPatient.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            KGGTherapistTabView(modelContext: modelContainer.mainContext)
                .environment(\.modelContext, modelContainer.mainContext)
        }
    }
}
