//
//  KGGLibraryRepository.swift
//  AgilKGG
//
//  Verwaltet die Praxis-Übungsbibliothek inkl. verschlüsselter Video-Ablage
//  und das flexible Kategorie-System.
//

import Foundation
import SwiftData
import CryptoKit
import AVFoundation
import UIKit
import AgilCore

@MainActor
public final class KGGLibraryRepository {

    private let modelContext: ModelContext
    private let cryptor = KGGVideoCryptor()
    private let keyManager: KeyManager
    private let keychain: KeychainStore

    private let keyService = "de.agil.kgg.videokeys"

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.keychain = KeychainStore(service: keyService)
        self.keyManager = KeyManager(keychain: keychain)
    }

    // MARK: - Library-Ordner

    private var libraryFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("KGGLibrary", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    // MARK: - Übungen laden

    public func fetchExercises(praxisId: UUID) throws -> [KGGLibraryExercise] {
        var descriptor = FetchDescriptor<KGGLibraryExercise>()
        descriptor.predicate = #Predicate<KGGLibraryExercise> { $0.praxisId == praxisId }
        descriptor.sortBy = [SortDescriptor(\KGGLibraryExercise.title)]
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Übung anlegen (mit Kategorien)

    @discardableResult
    public func createExercise(
        title: String,
        praxisId: UUID,
        muskel: String? = nil,
        muskelSub: String? = nil,
        gelenk: String? = nil,
        gelenkSub: String? = nil,
        geraet: String? = nil,
        geraetSub: String? = nil,
        bewegung: String? = nil,
        bewegungSub: String? = nil,
        notes: String? = nil
    ) throws -> KGGLibraryExercise {
        let exercise = KGGLibraryExercise(
            title: title,
            praxisId: praxisId,
            notes: notes
        )
        exercise.muskel = muskel
        exercise.muskelSub = muskelSub
        exercise.gelenk = gelenk
        exercise.gelenkSub = gelenkSub
        exercise.geraet = geraet
        exercise.geraetSub = geraetSub
        exercise.bewegung = bewegung
        exercise.bewegungSub = bewegungSub

        modelContext.insert(exercise)
        try modelContext.save()
        return exercise
    }

    // MARK: - Video verschlüsselt anhängen

    public func attachVideo(sourceURL: URL, to exercise: KGGLibraryExercise) throws {
        let key = keyManager.makeEphemeralKey()
        let keyAccount = "videokey_\(exercise.id.uuidString)"

        let fileName = "\(exercise.id.uuidString).agkv"
        let destURL = libraryFolder.appendingPathComponent(fileName)
        try cryptor.encrypt(sourceURL: sourceURL, to: destURL, using: key)

        try keychain.save(key.asData, account: keyAccount, protection: .deviceOnly)

        if let thumb = Self.generateThumbnail(from: sourceURL) {
            exercise.thumbnailData = thumb
        }

        exercise.encryptedFileName = fileName
        exercise.keychainKeyAccount = keyAccount
        exercise.hasVideo = true
        exercise.lastModified = Date()
        try modelContext.save()
    }

    public func encryptedVideoURL(for exercise: KGGLibraryExercise) -> URL? {
        guard let name = exercise.encryptedFileName else { return nil }
        return libraryFolder.appendingPathComponent(name)
    }

    public func videoKey(for exercise: KGGLibraryExercise) throws -> SymmetricKey? {
        guard let account = exercise.keychainKeyAccount,
              let data = try keychain.load(account: account) else { return nil }
        return SymmetricKey(data: data)
    }

    // MARK: - Löschen

    public func deleteExercise(_ exercise: KGGLibraryExercise) throws {
        if let url = encryptedVideoURL(for: exercise) {
            try? FileManager.default.removeItem(at: url)
        }
        if let account = exercise.keychainKeyAccount {
            keychain.delete(account: account)
        }
        modelContext.delete(exercise)
        try modelContext.save()
    }

    // MARK: - Kategorie-Werte (wachsend pro Praxis)

    public func fetchCategoryValues(
        category: KGGCategoryType,
        praxisId: UUID,
        parentValue: String? = nil
    ) throws -> [KGGCategoryValue] {
        let raw = category.rawValue
        var descriptor = FetchDescriptor<KGGCategoryValue>()
        descriptor.predicate = #Predicate<KGGCategoryValue> { val in
            val.praxisId == praxisId && val.categoryRaw == raw && val.parentValue == parentValue
        }
        descriptor.sortBy = [SortDescriptor(\KGGCategoryValue.value)]
        return try modelContext.fetch(descriptor)
    }

    @discardableResult
    public func addCategoryValue(
        category: KGGCategoryType,
        value: String,
        parentValue: String? = nil,
        praxisId: UUID
    ) throws -> KGGCategoryValue {
        // Duplikat vermeiden
        let existing = try fetchCategoryValues(category: category, praxisId: praxisId, parentValue: parentValue)
        if let dup = existing.first(where: { $0.value.caseInsensitiveCompare(value) == .orderedSame }) {
            return dup
        }
        let newValue = KGGCategoryValue(
            category: category,
            value: value,
            parentValue: parentValue,
            praxisId: praxisId
        )
        modelContext.insert(newValue)
        try modelContext.save()
        return newValue
    }

    // MARK: - Thumbnail

    static func generateThumbnail(from url: URL) -> Data? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 600, height: 600)
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.7)
    }
}
