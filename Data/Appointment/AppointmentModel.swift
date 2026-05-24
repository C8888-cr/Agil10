//
//  Appointment.swift
//  Agil7.0
//
//  Created by Christiane Roth on 07.10.25.
//

// Features/Appointments/Domain/Entities/Appointment.swift
import SwiftData
import Foundation
import CoreLocation
import MapKit

@Model
final class Appointment {
    @Attribute(.unique) var id: UUID
  
    var date: Date
    var therapist: String?
    var notes: String?
    var durationMinutes: Int = 20
    
    // MARK: - Location (✅ KOMPLETT!)
       var locationName: String?
       var locationAddress: String?
       var locationLatitude: Double?
       var locationLongitude: Double?
    
    // MARK: - Status & Tracking
    var statusRaw: String
    var emailUID: String?         // Email-Tracking für Import
    var lastModified: Date
    var isHighlighted: Bool       // Für Änderungs-Badge
    var wasNotified: Bool         // User hat Änderung gesehen
    
    var userId: UUID?  // Wer hat diesen Termin gebucht?
    var therapistId: UUID?  // Welcher Therapeut? (optional, falls noch nicht zugewiesen)
    var praxisId: UUID? // Zu welcher Praxis gehört der Termin?
    
    // MARK: - Computed Status
    var status: AppointmentStatus {
        get { AppointmentStatus(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }
    
    // MARK: - Location Computed
       var hasLocation: Bool {
           locationName != nil || locationAddress != nil
       }
       
       var coordinate: CLLocationCoordinate2D? {
           guard let lat = locationLatitude,
                 let lon = locationLongitude else { return nil }
           return CLLocationCoordinate2D(latitude: lat, longitude: lon)
       }
       
       var displayLocation: String? {
           if let name = locationName, let address = locationAddress {
               return "\(name)\n\(address)"
           }
           return locationName ?? locationAddress
       }
    
    
    var calendarEventIdentifier: String?
    
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        date: Date,
        therapist: String? = nil,
        locationName: String? = nil,
        locationAddress: String? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        notes: String? = nil,
        durationMinutes: Int = 20,
        emailUID: String? = nil,
        status: AppointmentStatus = .scheduled,
        userId: UUID,
        therapistId: UUID? = nil,
        praxisId: UUID,
        calendarEventIdentifier: String? = nil
    ) {
        self.id = id
        self.date = date
        self.therapist = therapist
        self.locationName = locationName
        self.locationAddress = locationAddress
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.notes = notes
        self.durationMinutes = durationMinutes
        self.emailUID = emailUID
        self.statusRaw = status.rawValue
        self.lastModified = Date()
        self.isHighlighted = false
        self.wasNotified = false
        self.userId = userId
        self.therapistId = therapistId
        self.praxisId = praxisId
        self.calendarEventIdentifier = calendarEventIdentifier
    }
}

// MARK: - Location Helpers
extension Appointment {
    func updateLocation(
        name: String?,
        address: String?,
        coordinate: CLLocationCoordinate2D?
    ) {
        self.locationName = name
        self.locationAddress = address
        self.locationLatitude = coordinate?.latitude
        self.locationLongitude = coordinate?.longitude
        self.lastModified = Date()
    }
    
    func openInMaps() {
        guard let coordinate = coordinate else { return }
        
        let name = locationName ?? "Termin"
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let address = locationAddress.flatMap {
               MKAddress(fullAddress: $0, shortAddress: locationName)
           }
        
        let mapItem = MKMapItem(location: location, address: address)
           mapItem.name = name
        
      
        
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}







// MARK: - Computed Properties
extension Appointment {
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    var fullDateTimeString: String {
        "\(dateString) um \(timeString)"
    }
    
    var isPast: Bool {
        date < Date()
    }
    
    var isUpcoming: Bool {
        date > Date()
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(date)
    }
    
    var daysUntilAppointment: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
    
    var relativeTimeString: String {
        let days = daysUntilAppointment
        
        if isToday {
            return "Heute"
        } else if isTomorrow {
            return "Morgen"
        } else if days > 0 && days <= 7 {
            return "In \(days) Tagen"
        } else if days > 7 && days <= 30 {
            let weeks = days / 7
            return "In \(weeks) Woche\(weeks == 1 ? "" : "n")"
        } else if isPast {
            return "Vorbei"
        } else {
            return dateString
        }
    }
}
