//
//  ValidationHelper.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


//
//  ValidationHelper.swift
//  Agil9.0
//
//  Created by Christiane Roth on 11.11.25.
//

import Foundation
struct ValidationHelper {
    
    // ✅ Email validieren
    static func isValidEmail(_ email: String) -> Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailRegex = try! NSRegularExpression(pattern: emailPattern)
        let range = NSRange(email.startIndex..<email.endIndex, in: email)
        return emailRegex.firstMatch(in: email, range: range) != nil
    }
    
    // 🔐 PASSWORT VALIDIEREN - Alle Anforderungen
    static func validatePassword(_ password: String) -> PasswordValidationResult {
        var result = PasswordValidationResult()
        
        // 1️⃣ Mindestlänge: 8 Zeichen
        result.hasMinimumLength = password.count >= 8
        
        // 2️⃣ Mindestens 1 Großbuchstabe
        result.hasUppercase = password.contains(where: { $0.isUppercase })
        
        // 3️⃣ Mindestens 1 Kleinbuchstabe
        result.hasLowercase = password.contains(where: { $0.isLowercase })
        
        // 4️⃣ Mindestens 1 Ziffer
        result.hasNumber = password.contains(where: { $0.isNumber })
        
        // 5️⃣ Mindestens 1 Sonderzeichen
        let specialCharacters = "!@#$%^&*()_+-=[]{}|;:',.<>?/\\"
        result.hasSpecialCharacter = password.contains(where: { specialCharacters.contains($0) })
        
        return result
    }
    
    // ✅ Ist Passwort GÜLTIG? (alle Anforderungen erfüllt)
    static func isValidPassword(_ password: String) -> Bool {
        let result = validatePassword(password)
        return result.isValid
    }
    
    // ✅ Passwörter stimmen überein?
    static func doPasswordsMatch(_ password1: String, _ password2: String) -> Bool {
        return password1 == password2 && !password1.isEmpty
    }
}
// 📊 Validierungs-Ergebnis (für Real-Time Feedback)
struct PasswordValidationResult {
    var hasMinimumLength: Bool = false      // ✓ Mindestens 8 Zeichen
    var hasUppercase: Bool = false          // ✓ Mindestens 1 Großbuchstabe (A-Z)
    var hasLowercase: Bool = false          // ✓ Mindestens 1 Kleinbuchstabe (a-z)
    var hasNumber: Bool = false             // ✓ Mindestens 1 Ziffer (0-9)
    var hasSpecialCharacter: Bool = false   // ✓ Mindestens 1 Sonderzeichen (!@#$...)
    
    // 🎯 Alle Anforderungen erfüllt?
    var isValid: Bool {
        hasMinimumLength && hasUppercase && hasLowercase && hasNumber && hasSpecialCharacter
    }
    
    // 📈 Passwort-Stärke in Prozent
    var strength: Double {
        let requirements = [hasMinimumLength, hasUppercase, hasLowercase, hasNumber, hasSpecialCharacter]
        let fulfilledCount = requirements.filter { $0 }.count
        return Double(fulfilledCount) / Double(requirements.count)
    }
    
    // 🏅 Passwort-Stärke als Text
    var strengthLabel: String {
        switch strength {
        case 0..<0.4:
            return "Sehr schwach"
        case 0.4..<0.6:
            return "Schwach"
        case 0.6..<0.8:
            return "Mittel"
        case 0.8..<1.0:
            return "Stark"
        case 1.0:
            return "Sehr stark"
        default:
            return "Unbekannt"
        }
    }
    
    // 🎨 Farbe für Stärke-Anzeige
    var strengthColor: String {
        switch strength {
        case 0..<0.4:
            return "red"
        case 0.4..<0.6:
            return "orange"
        case 0.6..<0.8:
            return "yellow"
        case 0.8..<1.0:
            return "lightGreen"
        case 1.0:
            return "green"
        default:
            return "gray"
        }
    }
}
