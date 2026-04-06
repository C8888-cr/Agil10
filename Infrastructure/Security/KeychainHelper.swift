//
//  KeychainHelper.swift
//  Agil10.0
//
//  Created by Christiane Roth on 25.12.25.
//


import Foundation
import Security


struct KeychainHelper {
    
    // ✅ Token speichern
    static func save(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Lösche alten Eintrag
        SecItemDelete(query as CFDictionary)
        
        // Speichere neuen
        SecItemAdd(query as CFDictionary, nil)
    }
    
    // ✅ Token laden
    static func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // ✅ Token löschen
    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
