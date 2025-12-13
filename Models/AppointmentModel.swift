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
    // MARK: - Core Properties
    @Attribute(.unique) var id: UUID
    var date: Date
    var therapist: String
    var notes: String?
    
    // MARK: - Location (✅ KOMPLETT!)
       var locationName: String?           // "Praxis Mitte"
       var locationAddress: String?        // "Hauptstraße 42, 10115 Berlin"
       var locationLatitude: Double?       // 52.520008
       var locationLongitude: Double?      // 13.404954
    
    // MARK: - Status & Tracking
    var statusRaw: String
    var emailUID: String?         // Email-Tracking für Import
    var lastModified: Date
    var isHighlighted: Bool       // Für Änderungs-Badge
    var wasNotified: Bool         // User hat Änderung gesehen
    
    // MARK: - Relationships
    var user: User?
    
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
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        date: Date,
        therapist: String,
        locationName: String? = nil,
        locationAddress: String? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        notes: String? = nil,
        emailUID: String? = nil,
        status: AppointmentStatus = .scheduled,
        user: User? = nil
    ) {
        self.id = id
        self.date = date
        self.therapist = therapist
        self.locationName = locationName
        self.locationAddress = locationAddress
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.notes = notes
        self.emailUID = emailUID
        self.statusRaw = status.rawValue
        self.lastModified = Date()
        self.isHighlighted = false
        self.wasNotified = false
        self.user = user
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
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
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
// MARK: - Identifiable
extension Appointment: Identifiable { }
// MARK: - Hashable (für SwiftUI ForEach)
extension Appointment: Hashable {
    static func == (lhs: Appointment, rhs: Appointment) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
