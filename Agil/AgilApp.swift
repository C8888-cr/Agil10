import SwiftUI
import SwiftData
import Firebase

@main
struct AgilApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var dependencies = AppDependencies.shared
    
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .tint(themeManager.currentTheme.accentColor)
                .environmentObject(dependencies)
         
                .environmentObject(dependencies.sessionManager)
                .environmentObject(dependencies.appointmentViewModel)
                .environmentObject(dependencies.icsImportCoordinator)
                .onOpenURL { url in
    // Per "Öffnen mit" empfangene .ics an den Coordinator geben.
                dependencies.icsImportCoordinator.handleIncomingURL(url)
                                }
                .environmentObject(dependencies.calendarViewModel)
                .environmentObject(dependencies.progressViewModel)
                .environmentObject(dependencies.workoutHistoryViewModel)
                .environmentObject(dependencies.settingsViewModel)
                .environmentObject(dependencies.profileViewModel)
                .environmentObject(dependencies.videoLibraryVM)
                .environment(\.modelContext, dependencies.modelContext)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
        }

                .onChange(of: scenePhase) { _, newPhase in
                   print("🔄 ScenePhase: \(newPhase)")
                   switch newPhase {
                   case .background:
                       print("📱 → didEnterBackground()")
                       dependencies.sessionManager.didEnterBackground()
                   case .active:
                       print("📱 → didEnterForeground()")
                       dependencies.sessionManager.didEnterForeground()
                   case .inactive:
                       print("📱 → inactive (skip)")
                       break
                   @unknown default:
                       break
                   }
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
