//
//  PersistenceController.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//
import SwiftData
import Foundation

@MainActor
class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            Appointment.self,
            User.self,
            UserPreferences.self,
            DayGoal.self,
            Video.self,
            VideoSchedule.self,
            TempoProtocol.self,
            WorkoutLog.self,
            KGGScannedExerciseModel.self,
            KGGScannedWarmupModel.self
         //   Exercise.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        // ✅ Container initialisieren
        do {
            self.container = try ModelContainer(for: schema, configurations: config)
            print("✅ ModelContainer created with PERSISTENT storage")
            print("✅ Schema: \(schema.entities.map { $0.name }.joined(separator: ", "))")
            
        } catch {
            print("❌ SwiftData Container FAIL: \(error)")
            print("🗑️ Versuche alte DB zu löschen...")
            
            // Statische Methode zum Löschen
            Self.deleteStore()
            
            // Neu versuchen
            do {
                self.container = try ModelContainer(for: schema, configurations: config)
                print("✅ Neuer Container nach DB-Reset erstellt")
            } catch {
                // NOTFALL: In-Memory Container
                let inMemoryConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                self.container = try! ModelContainer(for: schema, configurations: inMemoryConfig)
                fatalError("💥 Auch nach Delete failed: \(error)")
            }
        }
        
        // ✅ Migration nach erfolgreicher Initialisierung
                migrateStartTime()

                // 🔒 Data Protection: DB wird unlesbar, sobald das Gerät gesperrt ist
                Self.applyFileProtection()
            }
    
    // ✅ Migration: Fülle startTime für alte Einträge
    private func migrateStartTime() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<VideoSchedule>()
        
        do {
            let schedules = try context.fetch(descriptor)
            var updated = 0
            
            for schedule in schedules {
                // Nur wenn startTime optional ist (var startTime: Date?)
                if schedule.startTime == nil {
                    schedule.startTime = schedule.scheduledDate
                    updated += 1
                }
            }
            
            if updated > 0 {
                try context.save()
                print("✅ Migrated \(updated) VideoSchedules with startTime")
            }
            
        } catch {
            print("⚠️ Migration failed: \(error)")
        }
    }
    
    // ✅ Statische Methode zum Löschen der DB
    private static func deleteStore() {
        let fileManager = FileManager.default
        let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
        
        do {
            // Hauptdatei
            if fileManager.fileExists(atPath: storeURL.path()) {
                try fileManager.removeItem(at: storeURL)
                print("🗑️ Gelöscht: default.store")
            }
            
            // SQLite Hilfsdateien
            let shmURL = URL.applicationSupportDirectory.appending(path: "default.store-shm")
            let walURL = URL.applicationSupportDirectory.appending(path: "default.store-wal")
            
            if fileManager.fileExists(atPath: shmURL.path()) {
                try fileManager.removeItem(at: shmURL)
                print("🗑️ Gelöscht: default.store-shm")
            }
            if fileManager.fileExists(atPath: walURL.path()) {
                try fileManager.removeItem(at: walURL)
                print("🗑️ Gelöscht: default.store-wal")
            }
            
        } catch {
            print("⚠️ Konnte DB nicht löschen: \(error)")
        }
    }
    
    
    // 🔒 Data Protection auf SQLite-Dateien anwenden
        private static func applyFileProtection() {
            let fileManager = FileManager.default
            let files = ["default.store", "default.store-shm", "default.store-wal"]

            for file in files {
                let url = URL.applicationSupportDirectory.appending(path: file)
                guard fileManager.fileExists(atPath: url.path()) else { continue }

                do {
                    try (url as NSURL).setResourceValue(
                        URLFileProtection.completeUnlessOpen,
                        forKey: .fileProtectionKey
                    )
                    print("🔒 File protection set: \(file)")
                } catch {
                    print("⚠️ File protection failed for \(file): \(error)")
                }
            }
        }
    
    
}
