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
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel   // 👈 global injiziert
    

    
    var body: some View {
        if let _ = appState.currentUser {
   
                TabView {
                    
                    
                    NavigationStack {
                        HomeView(currentUser: settingsVM.user)
                    }
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .environmentObject(TrainingData(weeklySettings: WeeklySettings()))
                    .environmentObject(WeeklySettings())

                    
                    NavigationStack {
                        AppointmentView(viewModel: appointmentViewModel, currentUser: settingsVM.user)
                    }
                        .tabItem { Label("Appointments", systemImage: "person.fill") }
                    
                    NavigationStack {
                        CalendarView(
                            currentUser: settingsVM.user,
                            repository: videoLibraryVM.repository)
                    }
                    .tabItem { Label("Calendar", systemImage: "calendar") }
                    
                    NavigationStack {
                        ProgressTabView()
                    }
                        .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                    
                    NavigationStack {
                        LibraryView(
                            currentUser: settingsVM.user,
                            repository: videoLibraryVM.repository)
                    }
                    .tabItem { Label("Library", systemImage: "book.fill") }
                }
              
              
            
        } else {
            LoginView(loggedInUser: .constant(nil), authService: MockAuthService())
        }
    }
}
