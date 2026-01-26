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
                        .environmentObject(AppDependencies.shared.authService)
                        .environmentObject(AppDependencies.shared.progressViewModel)
                        .environmentObject(AppDependencies.shared.videoLibraryVM)
                        .environmentObject(AppDependencies.shared.settingsViewModel)
                        .environmentObject(AppDependencies.shared.profileViewModel)
                        .environmentObject(WeeklySettings())
                        
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                
                NavigationStack {
                    AppointmentView(viewModel: AppDependencies.shared.appointmentViewModel)
                        .environmentObject(AppDependencies.shared.appointmentViewModel)  // ← HINZUFÜGEN!
                        .environmentObject(AppDependencies.shared.authService)
                        .environmentObject(AppDependencies.shared.settingsViewModel)
                        .environmentObject(AppDependencies.shared.profileViewModel)
                }
                .tabItem { Label("Appointments", systemImage: "person.fill") }
                
                NavigationStack {
                    CalendarView(repository: AppDependencies.shared.videoRepository)
                        .environmentObject(AppDependencies.shared.calendarViewModel)
                        .environmentObject(AppDependencies.shared.authService)
                        .environmentObject(AppDependencies.shared.progressViewModel)
                        .environmentObject(AppDependencies.shared.videoLibraryVM)
                        .environmentObject(AppDependencies.shared.settingsViewModel)
                        .environmentObject(WeeklySettings())
                        .environmentObject(AppDependencies.shared.profileViewModel)
                
                }
                .tabItem { Label("Calendar", systemImage: "calendar") }
                
                NavigationStack {
                    ProgressTabView()
                        .environmentObject(AppDependencies.shared.authService)
                        .environmentObject(AppDependencies.shared.progressViewModel)
                        .environmentObject(AppDependencies.shared.settingsViewModel)
                        .environmentObject(AppDependencies.shared.profileViewModel)
                }
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                
                NavigationStack {
                    LibraryView()
                        .environmentObject(AppDependencies.shared.authService)
                        .environmentObject(AppDependencies.shared.videoLibraryVM)
                        .environmentObject(AppDependencies.shared.settingsViewModel)
                        .environmentObject(AppDependencies.shared.profileViewModel)
                 
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
