import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {

            TabView {
                NavigationStack {
                    HomeView()
                        .environmentObject(AppDependencies.shared.progressViewModel)
                        .environmentObject(AppDependencies.shared.videoLibraryVM)
                        .environmentObject(AppDependencies.shared.settingsViewModel)
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                
                NavigationStack {
                    AppointmentView(viewModel: AppDependencies.shared.appointmentViewModel)
                }
                .tabItem { Label("Appointments", systemImage: "person.fill") }
                
                NavigationStack {
                    CalendarView(repository: AppDependencies.shared.videoRepository)
                }
                .tabItem { Label("Calendar", systemImage: "calendar") }
                
                NavigationStack {
                    ProgressTabView()
                }
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                
                NavigationStack {
                    LibraryView(repository: AppDependencies.shared.videoRepository,
                                user: appState.currentUser)
                    .environmentObject(AppDependencies.shared.settingsViewModel)
                    .environmentObject(appState)
                }
                .tabItem { Label("Library", systemImage: "book.fill") }
            }
        
    }
}
