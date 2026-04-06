import SwiftUI
import SwiftData
import Foundation


@MainActor
struct ContentView: View {
    @EnvironmentObject var authService: AuthService  // ← noch für andere VMs
    @EnvironmentObject var session: SessionManager   // ← NEU
    
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
                      // alte VMs syncen
                      authService.currentUser = user
                      authService.isAuthenticated = true
                  }
              } else {
                  VStack(spacing: 20) {
                      Button("Zur Anmeldung") {
                          Task { await authService.logout() }
                      }
                  }
              }
          }
}
