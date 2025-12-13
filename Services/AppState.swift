//
//  AppState.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


// MARK: - AppState.swift
import SwiftUI
import SwiftData
@MainActor
class AppState: ObservableObject {
    @Published var currentUser: User?
    let modelContext: ModelContext
    
    lazy var videoRepository = VideoRepository(modelContext: modelContext)
    lazy var trainingData = TrainingData(weeklySettings: userSettings)
    lazy var userSettings = WeeklySettings()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
}
