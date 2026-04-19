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
                .tabItem { Label("Heute", systemImage: "house.fill") }
                
                NavigationStack {
                    AppointmentView()
                }
                .tabItem { Label("Termine", systemImage: "person.fill") }
                
                NavigationStack {
                    CalendarMonthView()
                }
                .tabItem { Label("Kalender", systemImage: "calendar") }
                
                NavigationStack {
                    ProgressTabView()
                }
                .tabItem { Label("Fortschritt", systemImage: "chart.bar.xaxis") }
                
                NavigationStack {
                    LibraryView()
                }
                .tabItem { Label("Mediathek", systemImage: "book.fill") }
                
            }
            .task {
                       print("✅ Eingeloggt als: \(user.email)")
                       AppDependencies.shared.settingsViewModel.setUser(user)
                   }
             
               }
           }
}
