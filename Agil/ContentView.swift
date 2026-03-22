import SwiftUI
import SwiftData
import Foundation


@MainActor
struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    
    var body: some View {
        if let user = authService.currentUser {
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
        } else {
                  // ❌ Fallback: Kein User gefunden
                  VStack(spacing: 20) {
                      Image(systemName: "person.crop.circle.badge.exclamationmark")
                          .font(.system(size: 64))
                          .foregroundColor(.red)
                      
                      Text("Kein User gefunden")
                          .font(.headline)
                      
                      Text("Bitte melde dich erneut an")
                          .font(.subheadline)
                          .foregroundColor(.secondary)
                      
                      Button("Zur Anmeldung") {
                          Task {
                              await authService.logout()
                          }
                      }
                      .buttonStyle(.borderedProminent)
                  }
                  .padding()
              }
          }
      }
