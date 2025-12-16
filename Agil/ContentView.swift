import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    let user: User  // ← PARAMETER!
    
    var body: some View {

            TabView {
                NavigationStack {
                    HomeView(user: user)
                        .environmentObject(AppDependencies.shared.progressViewModel)
                        .environmentObject(AppDependencies.shared.videoLibraryVM)
                        .environmentObject(AppDependencies.shared.settingsViewModel)
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                
                NavigationStack {
                    AppointmentView(viewModel: AppDependencies.shared.appointmentViewModel,
                    currentUser: user)
                }
                .tabItem { Label("Appointments", systemImage: "person.fill") }
                
                NavigationStack {
                    CalendarView(currentUser: user, repository: AppDependencies.shared.videoRepository)
                }
                .tabItem { Label("Calendar", systemImage: "calendar") }
                
                NavigationStack {
                    ProgressTabView()
                }
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                
                NavigationStack {
                    LibraryView(currentUser: user, repository: AppDependencies.shared.videoRepository)
                }
                .tabItem { Label("Library", systemImage: "book.fill") }
            }
        
    }
}
