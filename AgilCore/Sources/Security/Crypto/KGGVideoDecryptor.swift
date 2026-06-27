//
//  KGGVideoDecryptor.swift
//  AgilCore
//
//  Chunked AES-GCM Entschlüsselung für KGG-Videos.
//  Liest das Chunk-Format, entschlüsselt Blöcke.
//  Zwei Zugriffsmodi: simple (URL -> Data) oder streaming (für ResourceLoader).
//

import Foundation
import CryptoKit

public struct KGGVideoDecryptor {

    public enum DecryptorError: LocalizedError {
        case sourceNotReadable
        case badHeader
        case badMagic
        case unsupportedVersion(UInt8)
        case chunkReadFailed
        case decryptionFailed

        public var errorDescription: String? {
            switch self {
            case .sourceNotReadable:         return "Verschlüsselte Datei konnte nicht gelesen werden."
            case .badHeader:                 return "Header ist beschädigt."
            case .badMagic:                  return "Keine gültige KGG-Videodatei (falsches Magic)."
            case .unsupportedVersion(let v): return "KGG-Format Version \(v) wird nicht unterstützt."
            case .chunkReadFailed:           return "Chunk konnte nicht gelesen werden."
            case .decryptionFailed:          return "Entschlüsselung fehlgeschlagen (falscher Key?)."
            }
        }
    }

    private let crypto = CryptoService()

    public init() {}

    // MARK: - Simple Variante: URL -> Data (Gegentesten, kleine Videos)

    /// Entschlüsselt die gesamte Datei in einen Data-Buffer.
    /// ⚠️ Hält das ganze Video im RAM — nur für Test/kleine Videos!
    public func decrypt(sourceURL: URL, using key: SymmetricKey) throws -> Data {
        guard let input = InputStream(url: sourceURL) else {
            throw DecryptorError.sourceNotReadable
        }
        defer { input.close() }
        input.open()

        // Header lesen & validieren
        let (version, _) = try readHeader(from: input)
        guard version <= KGGVideoCryptor.version else {
            throw DecryptorError.unsupportedVersion(version)
        }

        // Chunks lesen & entschlüsseln
        var plainData = Data()
        while input.hasBytesAvailable {
            guard let block = try readChunk(from: input) else { break }
            let plain = try crypto.decrypt(block, using: key)
            plainData.append(plain)
        }

        return plainData
    }

    // MARK: - Streaming-Hilfsfunktionen (für ResourceLoader)

    /// Liest Header und gibt Metadaten zurück (cached vom ResourceLoader).
    public func readMetadata(from fileURL: URL) throws -> (version: UInt8, chunkSize: Int) {
        guard let input = InputStream(url: fileURL) else {
            throw DecryptorError.sourceNotReadable
        }
        defer { input.close() }
        input.open()
        return try readHeader(from: input)
    }

    /// Erzeugt einen Input-Stream für die Datei (ResourceLoader benutzt das).
    public func openInputStream(for fileURL: URL) throws -> InputStream {
        guard let input = InputStream(url: fileURL) else {
            throw DecryptorError.sourceNotReadable
        }
        return input
    }

    /// Dekryptiert einen einzelnen Sealed-Block (für ResourceLoader).
    public func decryptChunk(_ sealed: Data, using key: SymmetricKey) throws -> Data {
        return try crypto.decrypt(sealed, using: key)
    }

    // MARK: - Private: Chunk-Format lesen

    private func readHeader(from input: InputStream) throws -> (version: UInt8, chunkSize: Int) {
        var magicBytes = [UInt8](repeating: 0, count: 4)
        guard input.read(&magicBytes, maxLength: 4) == 4 else {
            throw DecryptorError.badHeader
        }
        guard Data(magicBytes) == KGGVideoCryptor.magic else {
            throw DecryptorError.badMagic
        }

        var versionByte = [UInt8](repeating: 0, count: 1)
        guard input.read(&versionByte, maxLength: 1) == 1 else {
            throw DecryptorError.badHeader
        }

        var chunkSizeBytes = [UInt8](repeating: 0, count: 4)
        guard input.read(&chunkSizeBytes, maxLength: 4) == 4 else {
            throw DecryptorError.badHeader
        }
        let chunkSize = Int(UInt32(littleEndian: chunkSizeBytes.withUnsafeBytes { $0.load(as: UInt32.self) }))

        return (versionByte[0], chunkSize)
    }

    private func readChunk(from input: InputStream) throws -> Data? {
        var lengthBytes = [UInt8](repeating: 0, count: 4)
        let read = input.read(&lengthBytes, maxLength: 4)

        if read == 0 { return nil }  // EOF
        guard read == 4 else { throw DecryptorError.chunkReadFailed }

        let length = Int(UInt32(littleEndian: lengthBytes.withUnsafeBytes { $0.load(as: UInt32.self) }))
        guard length > 0 else { throw DecryptorError.chunkReadFailed }

        var sealedBlock = [UInt8](repeating: 0, count: length)
        guard input.read(&sealedBlock, maxLength: length) == length else {
            throw DecryptorError.chunkReadFailed
        }

        return Data(sealedBlock)
    }

    /// Erzeugt einen ResourceLoader für AVPlayerItem.
    public func createResourceLoader(
        encryptedFileURL: URL,
        decryptionKey: SymmetricKey
    ) throws -> KGGAssetResourceLoader {
        return try KGGAssetResourceLoader(
            encryptedFileURL: encryptedFileURL,
            decryptionKey: decryptionKey,
            decryptor: self
        )
    }
}
