import SwiftUI
import SwiftData



@main
struct AgilApp: App {
    let dependencies = AppDependencies.shared
    
    var body: some Scene {
        WindowGroup {
            AppRouter()  // ← Dein Router!
                .environment(\.modelContext, dependencies.modelContext)
                .environmentObject(dependencies.appState)           // ← USER!
                .environmentObject(dependencies.appointmentViewModel)
                .environmentObject(dependencies.progressViewModel)
                .environmentObject(dependencies.videoLibraryVM)
                .environmentObject(dependencies.settingsViewModel)
                .environmentObject(dependencies.trainingData)
                .environmentObject(dependencies.calendarViewModel)
                .environmentObject(dependencies.trainingViewModel)
        }
    }
}
