import Foundation

enum RecurrenceRule: String, Codable, CaseIterable, Identifiable {
    case single  = "Einmalig"
    case daily   = "Täglich"
    case weekly  = "Wöchentlich"
    case monthly = "Monatlich"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .single:  return "Nur an diesem Tag"
        case .daily:   return "Jeden Tag wiederholen"
        case .weekly:  return "Jede Woche am gleichen Wochentag"
        case .monthly: return "Jeden Monat am gleichen Wochentag"
        }
    }
}
