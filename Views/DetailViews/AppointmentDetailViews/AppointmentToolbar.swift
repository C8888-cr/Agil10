//
//  AppointmentToolbar.swift

import SwiftUI
import SwiftData

struct AppointmentToolbar: ToolbarContent {
    let showingManualEntry: () -> Void
    let showingEmailImport: () -> Void
    let showingProfile: () -> Void
    let showingSettings: () -> Void
    
    let authService: AuthService 
    
    var body: some ToolbarContent {
        // LINKS: Plus-Menü
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button("Manuell eintragen", action: showingManualEntry)
                Button("Aus Email importieren", action: showingEmailImport)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accent)
                    .font(.title3)
            }
        }
        
        // RECHTS: Profile-Menü
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button("Profil", action: showingProfile)
                Button("Einstellungen", action: showingSettings)
            } label: {
                // ✅ PROFILBILD STATT ICON
                         if let user = authService.currentUser,
                            let imageData = user.profileImage,
                            let uiImage = UIImage(data: imageData) {
                             Image(uiImage: uiImage)
                                 .resizable()
                                 .scaledToFill()
                                 .frame(width: 35, height: 35)
                                 .clipShape(Circle())
                         } else {
                             Circle()
                                 .fill(Color.accentColor.opacity(0.3))
                                 .frame(width: 35, height: 35)
                                 .overlay(
                                    Text(authService.currentUser?.initials ?? "?")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.accentColor)
                                 )
                         }
            }
        }
    }
}
// MARK: - Preview
#Preview {
    NavigationStack {
        Text("Content")
            .toolbar {
                AppointmentToolbar(
                    showingManualEntry: { print("Manual Entry") },
                    showingEmailImport: { print("Email Import") },
                    showingProfile: { print("Profile") },
                    showingSettings: { print("Settings") },
                    authService: AuthService(authServiceProtocol: MockAuthService())  // ✅ Direkt hier
                )
            }
    }
}
