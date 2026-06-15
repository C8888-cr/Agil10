//
//  AppointmentToolbar.swift

import SwiftUI
import SwiftData

struct AppointmentToolbar: ToolbarContent {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    
    let showingManualEntry: () -> Void
    let showingEmailImport: () -> Void
    let showingProfile: () -> Void

    let showingReminders: () -> Void
    let notificationsEnabled: Bool
    
    let session: SessionManager
    
    var body: some ToolbarContent {
        // LINKS: Plus-Menü
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 4) {
                Menu {
                    Button("Manuell eintragen", action: showingManualEntry)
                    Button("Aus Email importieren", action: showingEmailImport)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .font(.title3)
                }

                Button(action: showingReminders) {
                    Image(systemName: notificationsEnabled ? "bell.fill" : "bell.slash")
                        .foregroundStyle(notificationsEnabled ? themeManager.currentTheme.accentColor : .secondary)
                        .font(.title3)
                }
            }
        }
        
        // RECHTS: Profile-Menü
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: showingProfile) {
                // Profilbild
                if let user = session.currentUser,
                   let imageData = user.profileImage,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.3))
                        .frame(width: 35, height: 35)
                        .overlay(
                            Text(session.currentUser?.initials ?? "?")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(themeManager.currentTheme.accentColor)
                        )
                }
            
            }
        }
    }
}
/// MARK: - Preview
#Preview {
    let container = PreviewHelper.createModelContainer()
    let userRepository = UserRepository(modelContext: container.mainContext)
    let authenticator = LocalAuthBiometricAuthenticator()
    let preferences = UserDefaultsBiometricPreferences()
    let unlockUseCase = UnlockAppUseCase(
        authenticator: authenticator,
        preferences: preferences
    )
    let sessionManager = SessionManager(
                authService: LocalAuthService(),
                userRepository: userRepository,
        unlockUseCase: unlockUseCase,
        preferences: preferences
    )
    
    NavigationStack {
        Text("Content")
            .toolbar {
                AppointmentToolbar(
                    showingManualEntry: { print("Manual Entry") },
                    showingEmailImport: { print("Email Import") },
                    showingProfile: { print("Profile") },
                    showingReminders: { print("Reminder")},
                    notificationsEnabled: true,
                    session: sessionManager
                )
            }
    }
}
