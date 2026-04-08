import SwiftUI
import SwiftData
import Firebase

@main
struct AgilApp: App {
    @StateObject private var dependencies = AppDependencies.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
         
                .environmentObject(dependencies.sessionManager)
                .environmentObject(dependencies.appointmentViewModel)
                .environmentObject(dependencies.calendarViewModel)
                .environmentObject(dependencies.progressViewModel)
                .environmentObject(dependencies.settingsViewModel)
                .environmentObject(dependencies.profileViewModel)
                .environmentObject(dependencies.videoLibraryVM)
                .environment(\.modelContext, dependencies.modelContext)
                
        }
    }
}

// Separater View der authViewModel als StateObject hält
struct RootView: View {
    @EnvironmentObject var dependencies: AppDependencies
    @StateObject private var authViewModel: AuthViewModel
    
    init() {
        _authViewModel = StateObject(wrappedValue: AppDependencies.shared.makeAuthViewModel())
    }
    
    var body: some View {
        AppRouter()
            .environmentObject(authViewModel)
    }
}
