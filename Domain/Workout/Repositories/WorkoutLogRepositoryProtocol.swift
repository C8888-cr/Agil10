//
//  WorkoutLogRepositoryProtocol.swift
//  Agil10.0
//
//  Created by Christiane Roth on 01.06.26.
//


//
//  WorkoutLogRepositoryProtocol.swift
//  Agil
//
//  Abstraktion für das Lesen/Schreiben von WorkoutLogs.
//  Append-only-Design: kein update, kein single-delete.
//  Bulk-delete nur für DSGVO/Account-Löschung.
//

import Foundation

@MainActor
protocol WorkoutLogRepositoryProtocol {
    /// Fügt einen neuen Log-Eintrag ein und speichert den Context.
    func insert(_ log: WorkoutLog) throws

    /// Alle Logs eines Users, sortiert nach Datum (älteste zuerst).
    func fetchAll(userId: UUID) throws -> [WorkoutLog]

    /// Logs für ein bestimmtes Video — für Detailansicht / Verlaufs-Diagramm.
    func fetchByVideo(videoId: UUID, userId: UUID) throws -> [WorkoutLog]

    /// Logs in einem Datumsbereich — für Wochen-/Monats-Statistiken.
    func fetch(from startDate: Date, to endDate: Date, userId: UUID) throws -> [WorkoutLog]

    /// Löscht ALLE Logs eines Users (für Account-Löschung / Reset).
    func deleteAll(for userId: UUID) throws
}