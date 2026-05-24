//
//  ICSImportCoordinator.swift
//  Agil10.0
//
//  Created by Christiane Roth on 24.05.26.
//


//
//  ICSImportCoordinator.swift
//  Agil10.0
//
//  Kleiner zentraler Vermittler für den ICS-Import per "Öffnen mit".
//
//  Problem: onOpenURL wird auf App-Ebene (AgilApp) ausgelöst, der Import
//  und das Ergebnis-Sheet leben aber in AppointmentView. Statt die URL
//  quer durch die View-Hierarchie zu reichen, legt onOpenURL sie hier ab;
//  AppointmentView beobachtet diesen Coordinator und reagiert.
//
//  Single Source of Truth für "es liegt eine .ics zum Import bereit".
//

import Foundation

@MainActor
final class ICSImportCoordinator: ObservableObject {

    /// Die zuletzt per "Öffnen mit" empfangene .ics-Datei.
    /// AppointmentView beobachtet diese Property und startet den Import,
    /// sobald sie gesetzt wird. Nach Verarbeitung auf nil zurücksetzen.
    @Published var pendingFileURL: URL?

    /// Nimmt eine von iOS übergebene Datei-URL entgegen.
    /// - Returns: true, wenn es sich um eine .ics-Datei handelt und sie
    ///   angenommen wurde – sonst false (andere Dateitypen ignorieren).
    @discardableResult
    func handleIncomingURL(_ url: URL) -> Bool {
        guard url.pathExtension.lowercased() == "ics" else {
            print("ℹ️ ICSImportCoordinator: \(url.lastPathComponent) ist keine .ics – ignoriert")
            return false
        }
        print("📥 ICSImportCoordinator: .ics empfangen – \(url.lastPathComponent)")
        pendingFileURL = url
        return true
    }

    /// Liest den Textinhalt der wartenden Datei und gibt ihn zurück.
    ///
    /// Dateien, die per "Öffnen mit" aus anderen Apps kommen, liegen oft in
    /// einer sicherheits-zugriffsbeschränkten Sandbox. Daher wird der Zugriff
    /// korrekt mit start/stopAccessingSecurityScopedResource geklammert.
    ///
    /// - Returns: Dateiinhalt als String, oder nil bei Lesefehler.
    func readPendingFileContents() -> String? {
        guard let url = pendingFileURL else { return nil }

        let needsScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // .ics ist Text; UTF-8 ist der Standard. Fällt auf Latin-1
            // zurück, falls eine Datei doch anders kodiert ist.
            if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
                return utf8
            }
            return try String(contentsOf: url, encoding: .isoLatin1)
        } catch {
            print("⚠️ ICSImportCoordinator: Datei konnte nicht gelesen werden: \(error)")
            return nil
        }
    }

    /// Setzt den Zustand zurück – nach erfolgreichem oder abgebrochenem Import.
    func clear() {
        pendingFileURL = nil
    }
}