//
//  KGGWarmupRepository.swift
//  Agil10
//
//  Created by Christiane Roth on 13.07.26.
//


//
//  KGGWarmupRepository.swift
//  Agil
//
//  Repository Protocol für zugewiesene Warmups (Domain Layer).
//  Abstrahiert Storage-Details. Kein Update-per-ID nötig — bei jedem
//  Assignment-Scan wird der komplette Warmup-Satz ersetzt (Snapshot).
//

import Foundation

public protocol KGGWarmupRepository: Sendable {

    func replaceAll(_ warmups: [KGGScannedWarmup]) async throws

    func fetchVisible() async throws -> [KGGScannedWarmup]
    func deleteExpired() async throws
    func deleteAll() async throws
}