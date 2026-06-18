//
//  AgilTests.swift
//  AgilTests
//
//  Created by Christiane Roth on 19.11.25.
//
import Foundation
import Testing
@testable import Agil10_0
struct AgilTests {

    @Test func kggVideoEncryptDecryptRoundtrip() async throws {
        // MARK: - Setup
        let keyManager = KeyManager()
        let testKey = keyManager.makeEphemeralKey()
        let encryptor = KGGVideoCryptor()
        let decryptor = KGGVideoDecryptor()

        // MARK: - Test-Video laden (erstes lokales Video)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosDir = documentsURL.appendingPathComponent("Videos")
        
        let videoFiles = try FileManager.default.contentsOfDirectory(
            at: videosDir,
            includingPropertiesForKeys: [.fileSizeKey]
        )
        guard let testVideoURL = videoFiles.first else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kein Test-Video gefunden"])
        }

        // Original-Größe
        let originalData = try Data(contentsOf: testVideoURL)
        print("📹 Test-Video geladen: \(testVideoURL.lastPathComponent)")
        print("   Größe: \(originalData.count / 1024 / 1024) MB")

        // MARK: - Verschlüsseln
        let encryptedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("agkv")
        
        print("🔐 Verschlüssele...")
        try encryptor.encrypt(sourceURL: testVideoURL, to: encryptedURL, using: testKey)
        let encryptedSize = try FileManager.default.attributesOfItem(atPath: encryptedURL.path)[.size] as? Int64 ?? 0
        print("   ✅ Verschlüsselt: \(encryptedSize / 1024 / 1024) MB")

        // MARK: - Entschlüsseln
        print("🔓 Entschlüssele...")
        let decryptedData = try decryptor.decrypt(sourceURL: encryptedURL, using: testKey)
        print("   ✅ Entschlüsselt: \(decryptedData.count / 1024 / 1024) MB")

        // MARK: - Verify: Original == Decrypted
        #expect(originalData == decryptedData, "Verschlüsselt/Entschlüsselt stimmt nicht mit Original überein")
        #expect(originalData.count == decryptedData.count, "Größe stimmt nicht")
        
        print("✅ Roundtrip erfolgreich!")

        // MARK: - Cleanup
        try FileManager.default.removeItem(at: encryptedURL)
    }
}
