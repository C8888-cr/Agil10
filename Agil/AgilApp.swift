import SwiftUI
import SwiftData


@main
struct AgilApp: App {
    let dependencies = AppDependencies.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()  // ✅ Root View
                .environment(\.modelContext, dependencies.modelContext)
            
               
        }
    }
}


struct RootView: View {
    @EnvironmentObject var authService: AuthService
    
    
    var body: some View {
        AppRouter()  // ← AppRouter muss existieren!
            .environmentObject(AppDependencies.shared.authService)
            .environment(\.modelContext, AppDependencies.shared.modelContext)
            .task {
                await AppDependencies.shared.authService.loadSavedSession()
            }
    }
}
