//
//  ICSParserService.swift
//  Agil10.0
//
//  Created by Christiane Roth on 24.05.26.
//


//
//  ICSParserService.swift
//  Agil10.0
//
//  Parst .ics-Kalenderdateien (iCalendar / RFC 5545) zu [Appointment].
//  Architektonisch das Gegenstück zu EmailParserService: gleiche Rolle
//  (Service-Schicht), gleiche Ausgabe ([Appointment]) – nur eine andere
//  Quelle. Dadurch kann der ICS-Import durch dieselbe Verarbeitungskette
//  laufen wie der Email-Import (DetectChanges -> ImportResultsView).
//

import Foundation

@MainActor
class ICSParserService {

    // MARK: - Session (für userId / praxisId – identisch zu EmailParserService)

    private weak var session: SessionManager?

    init(session: SessionManager? = nil) {
        self.session = session
    }

    private var currentUserId: UUID {
        session?.currentUser?.id ?? UUID()
    }

    private var currentPraxisId: UUID {
        session?.currentUser?.praxisId ??
        PraxisDataManager.shared.praxen.first?.id ??
        PraxisDataManager.praxis1Id
    }

    // MARK: - Herkunfts-Merkmal

    /// Kennzeichen im SUMMARY, an dem ein "echter" Agil-Termin erkannt wird.
    /// Beispiel-SUMMARY: "Termin (Praxis agil Johannes Kurtz)".
    /// Case-insensitiv geprüft – siehe `looksLikeAgilFile`.
    private static let originMarker = "praxis agil"

    // MARK: - Ergebnis

    /// Ergebnis eines ICS-Parsing-Durchlaufs.
    /// `looksLikeAgil` = false bedeutet: Datei wurde gelesen, aber das
    /// SUMMARY enthält das Agil-Kennzeichen nicht. Die UI kann den Nutzer
    /// dann warnen ("scheint nicht von Agil zu stammen"), statt hart zu blocken.
    struct Result {
        let appointments: [Appointment]
        let looksLikeAgil: Bool
    }

    // MARK: - Public API

    /// Parst den Inhalt einer .ics-Datei.
    /// - Parameter icsText: Roher Dateiinhalt (UTF-8-String).
    /// - Returns: Geparste Termine + Herkunfts-Flag.
    func parseAppointments(from icsText: String) -> Result {
        print("\n📅 === ICS PARSING STARTED ===")

        // 1. Zeilen-Unfolding (RFC 5545): Folgezeilen beginnen mit Space/Tab
        //    und gehören an die vorige Zeile angehängt.
        let lines = unfoldLines(in: icsText)

        // 2. In VEVENT-Blöcke zerlegen und jeden Block einzeln parsen.
        var appointments: [Appointment] = []
        var sawAgilMarker = false

        for block in eventBlocks(in: lines) {
            guard let parsed = parseEvent(block) else { continue }
            if parsed.isAgil { sawAgilMarker = true }
            appointments.append(parsed.appointment)
        }

        print("📊 ERGEBNIS: \(appointments.count) Termin(e), Agil-Merkmal: \(sawAgilMarker)")
        print("=================================\n")

        return Result(appointments: appointments, looksLikeAgil: sawAgilMarker)
    }

    // MARK: - Zeilen-Unfolding

    /// Macht das ICS-Line-Folding rückgängig (RFC 5545, Abschnitt 3.1):
    /// Eine Zeile, die mit Space oder Tab beginnt, ist Fortsetzung der
    /// vorigen Zeile. Verarbeitet \r\n, \n und \r als Zeilenende.
    private func unfoldLines(in text: String) -> [String] {
        let rawLines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")

        var result: [String] = []
        for raw in rawLines {
            if let first = raw.first, first == " " || first == "\t" {
                // Fortsetzungszeile -> an vorige anhängen (führendes Zeichen weg)
                let continuation = String(raw.dropFirst())
                if result.isEmpty {
                    result.append(continuation)
                } else {
                    result[result.count - 1] += continuation
                }
            } else {
                result.append(raw)
            }
        }
        return result
    }

    // MARK: - VEVENT-Blöcke

    /// Sammelt alle Zeilen zwischen BEGIN:VEVENT und END:VEVENT.
    /// VTIMEZONE-Blöcke o.ä. werden ignoriert.
    private func eventBlocks(in lines: [String]) -> [[String]] {
        var blocks: [[String]] = []
        var current: [String]? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "BEGIN:VEVENT" {
                current = []
            } else if trimmed == "END:VEVENT" {
                if let block = current { blocks.append(block) }
                current = nil
            } else {
                current?.append(line)
            }
        }
        return blocks
    }

    // MARK: - Einzel-Event

    /// Parst einen einzelnen VEVENT-Block zu einem Appointment.
    /// Gibt nil zurück, wenn das Pflichtfeld DTSTART fehlt oder unlesbar ist.
    private func parseEvent(_ block: [String]) -> (appointment: Appointment, isAgil: Bool)? {
        var properties: [String: (params: String, value: String)] = [:]

        for line in block {
            // Eine ICS-Property: NAME[;PARAM=...]:VALUE
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let namePart = String(line[..<colonIndex])
            let value = String(line[line.index(after: colonIndex)...])

            // Property-Name vom Parameter-Teil trennen (am ersten ';')
            let name: String
            let params: String
            if let semicolon = namePart.firstIndex(of: ";") {
                name = String(namePart[..<semicolon]).uppercased()
                params = String(namePart[namePart.index(after: semicolon)...])
            } else {
                name = namePart.uppercased()
                params = ""
            }
            properties[name] = (params: params, value: value)
        }

        // DTSTART ist Pflicht – ohne Startzeitpunkt kein Termin.
        guard let dtStartRaw = properties["DTSTART"],
              let startDate = parseICSDate(value: dtStartRaw.value,
                                           params: dtStartRaw.params) else {
            print("  ⚠️ VEVENT ohne lesbares DTSTART übersprungen")
            return nil
        }

        // Dauer aus DTEND - DTSTART; Fallback 20 Min (= Appointment-Default).
        var durationMinutes = 20
        if let dtEndRaw = properties["DTEND"],
           let endDate = parseICSDate(value: dtEndRaw.value, params: dtEndRaw.params) {
            let minutes = Int(endDate.timeIntervalSince(startDate) / 60)
            if minutes > 0 { durationMinutes = minutes }
        }

        // SUMMARY: Herkunfts-Check. Therapeut wird NICHT gesetzt – in der
        // ICS steht kein Behandler, nur Praxisname + Inhaber.
        let summary = properties["SUMMARY"]?.value ?? ""
        let isAgil = summary.lowercased().contains(Self.originMarker)

        // LOCATION in Name + Adresse aufteilen.
        let (locName, locAddress) = splitLocation(properties["LOCATION"]?.value)

        // UID -> emailUID (stabile Termin-Identität für DetectChanges).
        let uid = properties["UID"]?.value.trimmingCharacters(in: .whitespaces)

        let appointment = Appointment(
            date: startDate,
            therapist: nil,                 // bewusst nil – nicht in der ICS enthalten
            locationName: locName,
            locationAddress: locAddress,
            notes: nil,
            durationMinutes: durationMinutes,
            emailUID: uid,                  // ICS-UID, z.B. "216848@Sovdwaer.de"
            userId: currentUserId,
            praxisId: currentPraxisId
        )

        print("  ✅ ICS-Termin: \(startDate) | UID: \(uid ?? "nil") | \(durationMinutes) Min")
        return (appointment: appointment, isAgil: isAgil)
    }

    // MARK: - Datum

    /// Parst einen ICS-Datumswert zu einem `Date`.
    /// Unterstützte Formate:
    ///   - "20260525T095000"  mit TZID=... im params  -> lokale Zonenzeit
    ///   - "20260525T095000Z"                          -> UTC
    ///   - "20260525"          (reines Datum)          -> Mitternacht
    private func parseICSDate(value: String, params: String) -> Date? {
        let raw = value.trimmingCharacters(in: .whitespaces)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if raw.hasSuffix("Z") {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter.date(from: raw)
        }

        if raw.contains("T") {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
            formatter.timeZone = timeZone(fromParams: params) ?? .current
            return formatter.date(from: raw)
        }

        // Reines Datum ohne Uhrzeit
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = timeZone(fromParams: params) ?? .current
        return formatter.date(from: raw)
    }

    /// Liest die Zeitzone aus einem Parameter-String wie "TZID=Europe/Berlin".
    private func timeZone(fromParams params: String) -> TimeZone? {
        for part in params.components(separatedBy: ";") {
            let kv = part.components(separatedBy: "=")
            if kv.count == 2, kv[0].uppercased() == "TZID" {
                return TimeZone(identifier: kv[1].trimmingCharacters(in: .whitespaces))
            }
        }
        return nil
    }

    // MARK: - Location

    /// Zerlegt den LOCATION-Wert in Name + Adresse.
    /// In den Agil-ICS steht dort nur eine Adresse ("Juchostr. 7, 60385
    /// Frankfurt") – kein separater Name. Daher: alles -> locationAddress,
    /// locationName bleibt nil. Sollte mal "Name, Adresse" kommen, wird am
    /// ersten Komma getrennt.
    private func splitLocation(_ raw: String?) -> (name: String?, address: String?) {
        guard let raw = raw?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else {
            return (nil, nil)
        }
        // ICS-escaping rückgängig machen (\, \; \n).
        let cleaned = raw
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\n", with: " ")
            .replacingOccurrences(of: "\\N", with: " ")
        return (nil, cleaned)
    }
}