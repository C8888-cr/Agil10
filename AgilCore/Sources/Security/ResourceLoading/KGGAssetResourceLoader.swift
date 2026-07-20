//
//  KGGAssetResourceLoader.swift
//  Agil10.0
//
//  AVAssetResourceLoaderDelegate für sicheres Streaming-Playback
//  von verschlüsselten KGG-Videos.
//  Der Player fragt nach Byte-Ranges, wir entschlüsseln nur nötige Chunks.
//

import Foundation
import AVFoundation
import CryptoKit

public class KGGAssetResourceLoader: NSObject, AVAssetResourceLoaderDelegate, @unchecked Sendable {
    private let encryptedFileURL: URL
    private let decryptionKey: SymmetricKey
    private let decryptor: KGGVideoDecryptor

    private var metadata: (version: UInt8, chunkSize: Int)?

    init(
        encryptedFileURL: URL,
        decryptionKey: SymmetricKey,
        decryptor: KGGVideoDecryptor
    ) throws {
        self.encryptedFileURL = encryptedFileURL
        self.decryptionKey = decryptionKey
        self.decryptor = decryptor
        super.init()

        // Metadaten beim Init laden
        self.metadata = try decryptor.readMetadata(from: encryptedFileURL)
    }

    // MARK: - AVAssetResourceLoaderDelegate

     public func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let dataRequest = loadingRequest.dataRequest else { return false }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let offset = Int64(dataRequest.requestedOffset)
                let length = Int64(dataRequest.requestedLength)
                let requestedRange = offset..<(offset + length)
                let data = try self.loadRange(requestedRange)
                dataRequest.respond(with: data)
                loadingRequest.finishLoading()
            } catch {
                loadingRequest.finishLoading(with: error)
            }
        }

        return true
    }

    // MARK: - Private: Range-Laden & Entschlüsseln

    private func loadRange(_ range: Range<Int64>) throws -> Data {
        guard metadata != nil else {
            throw KGGVideoDecryptor.DecryptorError.badHeader
        }

        let input = try decryptor.openInputStream(for: encryptedFileURL)
        defer { input.close() }
        input.open()

        // Header skippen (9 Bytes: 4 magic + 1 version + 4 chunkSize)
        var buffer = [UInt8](repeating: 0, count: 9)
        guard input.read(&buffer, maxLength: 9) == 9 else {
            throw KGGVideoDecryptor.DecryptorError.badHeader
        }

        var result = Data()
        var currentPos: Int64 = 0

        // Chunks durchlaufen, nur angeforderte Bereiche entschlüsseln
        while input.hasBytesAvailable {
            guard let sealed = try readChunk(from: input) else { break }

            let decrypted = try decryptor.decryptChunk(sealed, using: decryptionKey)
            let chunkEnd = currentPos + Int64(decrypted.count)

            // Überlapp mit angeforderten Range?
            if chunkEnd > range.lowerBound && currentPos < range.upperBound {
                let overlapStart = max(0, Int(range.lowerBound - currentPos))
                let overlapEnd = min(Int(decrypted.count), Int(range.upperBound - currentPos))
                result.append(decrypted[overlapStart..<overlapEnd])
            }

            currentPos = chunkEnd
            if currentPos >= range.upperBound { break }
        }

        return result
    }

    /// Liest einen Chunk aus dem Stream (copy der Logik aus Decryptor — könnte auch public extension sein).
    private func readChunk(from input: InputStream) throws -> Data? {
        var lengthBytes = [UInt8](repeating: 0, count: 4)
        let read = input.read(&lengthBytes, maxLength: 4)

        if read == 0 { return nil }
        guard read == 4 else { throw KGGVideoDecryptor.DecryptorError.chunkReadFailed }

        let length = Int(UInt32(littleEndian: lengthBytes.withUnsafeBytes { $0.load(as: UInt32.self) }))
        guard length > 0 else { throw KGGVideoDecryptor.DecryptorError.chunkReadFailed }

        var sealedBlock = [UInt8](repeating: 0, count: length)
        guard input.read(&sealedBlock, maxLength: length) == length else {
            throw KGGVideoDecryptor.DecryptorError.chunkReadFailed
        }

        return Data(sealedBlock)
    }
}
