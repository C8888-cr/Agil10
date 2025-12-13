//
//  EmailParserService.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


// Features/Appointments/Services/EmailParserService.swift
import Foundation
class EmailParserService {
    func parseAppointments(from emailText: String) -> [Appointment] {
        print("\n📧 === EMAIL PARSING STARTED ===")
        print("Email Text:\n\(emailText)")
        print("================================\n")
        
        var parsedAppointments: [Appointment] = []
        let lines = emailText.components(separatedBy: .newlines)
        let emailHash = emailText.hashValue.description
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            print("Zeile \(index): '\(trimmed)'")
            
            // Prüfen ob Zeile ein Termin ist (enthält Datum + Uhrzeit + Therapeut)
            // Format: "Mo    20.10.2025    12:00    KG (Frau Müller)"
            if let appointment = parseAppointmentLine(trimmed, emailHash: emailHash) {
                print("  ✅ Termin gefunden: \(appointment.date.formatted()) | \(appointment.therapist)")
                parsedAppointments.append(appointment)
            }
        }
        
        print("\n📊 ERGEBNIS: \(parsedAppointments.count) Termin(e) gefunden")
        print("=================================\n")
        
        return parsedAppointments
    }
    
    // MARK: - Private Helper Methods
    
    /// Parst eine Zeile im Format: "Mo    20.10.2025    12:00    KG (Frau Müller)"
    private func parseAppointmentLine(_ line: String, emailHash: String) -> Appointment? {
        // Tabs oder mehrere Leerzeichen als Trenner
        let components = line.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        guard components.count >= 4 else { return nil }
        
        // 1. Datum extrahieren (z.B. "20.10.2025" oder "20.102025")
        var dateString: String?
        var timeString: String?
        var therapistString: String?
        
        for (index, component) in components.enumerated() {
            // Datum suchen
            if dateString == nil, let extracted = extractDate(from: component) {
                dateString = normalizeDate(extracted)
                print("    → Datum: \(dateString ?? "nil")")
            }
            
            // Uhrzeit suchen
            if timeString == nil, let extracted = extractTime(from: component) {
                timeString = extracted
                print("    → Uhrzeit: \(timeString ?? "nil")")
            }
            
            // Therapeut: Alles nach der Uhrzeit, das "(Frau/Herr ...)" enthält
            if component.contains("(") && component.contains("Frau") || component.contains("Herr") {
                // Alle restlichen Komponenten zusammenfügen
                let remainingComponents = components[index...]
                let fullText = remainingComponents.joined(separator: " ")
                therapistString = extractTherapist(from: fullText)
                print("    → Therapeut: \(therapistString ?? "nil")")
                break
            }
        }
        
        // Prüfen ob alle Daten vorhanden
        guard let dateStr = dateString,
              let timeStr = timeString,
              let therapist = therapistString,
              let date = parseDate(dateStr),
              let fullDate = combineDateTime(date: date, time: timeStr) else {
            return nil
        }
        
        return Appointment(
            date: fullDate,
            therapist: therapist,
            emailUID: emailHash
        )
    }
    
    /// Normalisiert Datum von "20.102025" zu "20.10.2025"
    private func normalizeDate(_ dateString: String) -> String {
        // Entfernt alle Punkte und fügt sie korrekt ein
        let digitsOnly = dateString.replacingOccurrences(of: ".", with: "")
        
        // Format: DDMMYYYY → DD.MM.YYYY
        guard digitsOnly.count == 8 else { return dateString }
        
        let day = digitsOnly.prefix(2)
        let month = digitsOnly.dropFirst(2).prefix(2)
        let year = digitsOnly.suffix(4)
        
        return "\(day).\(month).\(year)"
    }
    
    private func extractDate(from text: String) -> String? {
        // Sucht nach "20.10.2025" oder "20.102025"
        let patterns = [
            #"\d{2}\.\d{2}\.\d{4}"#,  // 20.10.2025
            #"\d{2}\.\d{6}"#,         // 20.102025
            #"\d{8}"#                 // 20102025
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                return String(text[range])
            }
        }
        return nil
    }
    
    private func extractTime(from text: String) -> String? {
        let pattern = #"\d{2}:\d{2}"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        return nil
    }
    
    private func extractTherapist(from text: String) -> String? {
        // Extrahiert "Frau Müller" aus "KG (Frau Müller)"
        if let start = text.range(of: "("),
           let end = text.range(of: ")") {
            let therapist = String(text[start.upperBound..<end.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            return therapist.isEmpty ? nil : therapist
        }
        return nil
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = TimeZone.current
        
        return formatter.date(from: dateString)
    }
    
    private func combineDateTime(date: Date, time: String) -> Date? {
        let timeComponents = time.split(separator: ":")
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            return nil
        }
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        
        return Calendar.current.date(from: components)
    }
}
