import SwiftUI
import SwiftData


@main
struct AgilApp: App {
    @StateObject private var dependencies = AppDependencies.shared
    
    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(dependencies.authService)
                .environmentObject(dependencies.appointmentViewModel)
                .environmentObject(dependencies.calendarViewModel)
                .environmentObject(dependencies.progressViewModel)
                .environmentObject(dependencies.settingsViewModel)
                .environmentObject(dependencies.profileViewModel)
                .environmentObject(dependencies.videoLibraryVM)
                .environment(\.modelContext, dependencies.modelContext)
                .task {
                    await dependencies.authService.loadSavedSession()
                }
        }
    }
}
