import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @EnvironmentObject var appointmentViewModel: AppointmentViewModel
    @EnvironmentObject var trainingVM: TrainingViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var calVM: CalendarViewModel
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel
    
    var body: some View {
        if let currentUser = appState.currentUser {  // ← currentUser verfügbar!
            TabView {
                NavigationStack {
                    HomeView()  // ✅ KEIN Parameter!
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                
                NavigationStack {
                    AppointmentView(viewModel: appointmentViewModel, currentUser: currentUser)
                }
                .tabItem { Label("Appointments", systemImage: "person.fill") }
                
                NavigationStack {
                    CalendarView(currentUser: currentUser, repository: videoLibraryVM.repository)
                }
                .tabItem { Label("Calendar", systemImage: "calendar") }
                
                NavigationStack {
                    ProgressTabView()
                }
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                
                NavigationStack {
                    LibraryView(currentUser: currentUser, repository: videoLibraryVM.repository)
                }
                .tabItem { Label("Library", systemImage: "book.fill") }
            }
        } else {
            LoginView(loggedInUser: .constant(nil), authService: MockAuthService())
        }
    }
}
