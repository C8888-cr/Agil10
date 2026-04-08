import SwiftUI
import SwiftData
import Foundation


@MainActor
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var session: SessionManager
    
    var body: some View {
        if let user = session.currentUser {
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                
                NavigationStack {
                    AppointmentView()
                }
                .tabItem { Label("Appointments", systemImage: "person.fill") }
                
                NavigationStack {
                    CalendarView()
                }
                .tabItem { Label("Calendar", systemImage: "calendar") }
                
                NavigationStack {
                    ProgressTabView()
                }
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                
                NavigationStack {
                    LibraryView()
                }
                .tabItem { Label("Library", systemImage: "book.fill") }
                
            }
            .task {
                       print("✅ Eingeloggt als: \(user.email)")
                       AppDependencies.shared.settingsViewModel.setUser(user)
                   }
             
               }
           }
}
