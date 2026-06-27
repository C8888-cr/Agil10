//
//  KGGVideoCryptor.swift
//  AgilCore
//
//  Chunked AES-GCM Verschlüsselung für KGG-Videos (Art 2, Praxis-IP).
//  Streamt Datei -> Datei, hält nie das ganze Video im RAM.
//  Format (siehe Header-Konstanten): magic | version | chunkSize | [length | sealedBlock]*
//

import Foundation
import CryptoKit

public struct KGGVideoCryptor {

    // MARK: - Format-Konstanten (Single Source of Truth)
    public static let magic = Data("AGKV".utf8)          // 4 Bytes
    public static let version: UInt8 = 1
    public static let defaultChunkSize = 1 * 1024 * 1024 // 1 MB Klartext pro Chunk

    public enum CryptorError: LocalizedError {
        case sourceNotReadable
        case writeFailed
        case unsupportedFormat
        case unsupportedVersion(UInt8)

        public var errorDescription: String? {
            switch self {
            case .sourceNotReadable:        return "Quelldatei konnte nicht gelesen werden."
            case .writeFailed:              return "Verschlüsselte Datei konnte nicht geschrieben werden."
            case .unsupportedFormat:        return "Kein gültiges KGG-Videoformat."
            case .unsupportedVersion(let v): return "KGG-Format Version \(v) wird nicht unterstützt."
            }
        }
    }

    private let crypto = CryptoService()
    private let chunkSize: Int

    public init(chunkSize: Int = KGGVideoCryptor.defaultChunkSize) {
        self.chunkSize = chunkSize
    }

    // MARK: - Encrypt (Therapeuten-Seite): Klartext-Video -> verschlüsselter Blob

    /// Verschlüsselt die Datei unter `sourceURL` chunked nach `destinationURL`.
    /// Liest und schreibt streamend — das ganze Video ist nie komplett im RAM.
    public func encrypt(sourceURL: URL, to destinationURL: URL, using key: SymmetricKey) throws {
        guard let input = InputStream(url: sourceURL) else {
            throw CryptorError.sourceNotReadable
        }
        guard FileManager.default.createFile(atPath: destinationURL.path, contents: nil) else {
            throw CryptorError.writeFailed
        }
        guard let output = FileHandle(forWritingAtPath: destinationURL.path) else {
            throw CryptorError.writeFailed
        }
        defer { input.close(); try? output.close() }

        input.open()

        // Header schreiben: magic | version | chunkSize
        var header = Data()
        header.append(Self.magic)
        header.append(Self.version)
        header.append(uint32: UInt32(chunkSize))
        output.write(header)

        // Chunks lesen & sealen
        var buffer = [UInt8](repeating: 0, count: chunkSize)
        while input.hasBytesAvailable {
            let read = input.read(&buffer, maxLength: chunkSize)
            if read < 0 { throw CryptorError.sourceNotReadable }
            if read == 0 { break }

            let plain = Data(buffer[0..<read])
            let sealed = try crypto.encrypt(plain, using: key)   // AES-GCM combined (Nonce+CT+Tag)

            var block = Data()
            block.append(uint32: UInt32(sealed.count))            // length-Präfix
            block.append(sealed)
            output.write(block)
        }
    }
}

// MARK: - Little-Endian UInt32 Helper
private extension Data {
    mutating func append(uint32 value: UInt32) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { append(contentsOf: $0) }
    }
}
