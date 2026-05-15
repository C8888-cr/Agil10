//
//  BiometricCredentialStorage.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.05.26.
//


import Foundation

protocol BiometricCredentialStorage {
    func save(email: String, password: String) throws
    func load() async throws -> (email: String, password: String)
    func clear()
    var hasStoredCredentials: Bool { get }
}