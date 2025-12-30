//
//  AuthServiceSession.swift
//  Agil10.0
//
//  Created by Christiane Roth on 25.12.25.
//

//
//  AuthService+Session.swift
//  Agil10.0
//
//  Created by Christiane Roth on 22.12.25.
//
import SwiftUI
extension AuthService {
    
    /// ✅ Session beim App-Start laden
    func loadSavedSession() async {
        // ✅ Prüfe ob Token vorhanden
        guard KeychainHelper.load(forKey: "sessionToken") != nil else {
            print("⚠️ Kein gespeicherter Token gefunden")
            return
        }
        
        // ✅ Versuche User zu laden
        do {
            try await fetchCurrentUser()
            print("✅ Session wiederhergestellt")
        } catch {
            print("❌ Session konnte nicht geladen werden: \(error)")
            // Token ungültig → Logout
            await logout()
        }
    }
}
