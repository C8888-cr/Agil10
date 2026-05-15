//
//  SecureTokenStorage.swift
//  Agil10.0
//
//  Created by Christiane Roth on 11.05.26.
//
import Foundation

// Domain/Storage/SecureTokenStorage.swift
protocol SecureTokenStorage {
    func saveToken(_ token: String, requiresBiometry: Bool) throws
    func readToken() throws -> String?
    func deleteToken() throws
}
