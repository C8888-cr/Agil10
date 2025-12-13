//
//  VideoSource.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  VideoSource.swift
//  Agil7.0
//
//  Created by Christiane Roth on 14.10.25.
//

// Models/VideoSource.swift
enum VideoSource: String, Codable {
    case recorded = "recorded"      // Eigene aufgenommene Videos
    case downloaded = "downloaded"  // Heruntergeladene Videos
    case cloud = "cloud"            // Cloud-Videos (Stream oder Cache)
    
    var icon: String {
        switch self {
        case .recorded: return "camera.fill"
        case .downloaded: return "arrow.down.circle.fill"
        case .cloud: return "cloud.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .recorded: return "Aufgenommen"
        case .downloaded: return "Heruntergeladen"
        case .cloud: return "Cloud"
        }
    }
}
// Models/VideoAvailability.swift
enum VideoAvailability {
    case available          // Lokal verfügbar
    case cloudOnly         // Nur Cloud (Stream)
    case downloading(progress: Double)  // Download läuft
    case requiresPurchase  // Nicht freigeschaltet
}
