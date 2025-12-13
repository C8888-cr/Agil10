//
//  Practice.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import SwiftData
import Foundation
import CoreLocation
import MapKit
@Model
final class Praxis {
    @Attribute(.unique) var id: Int
    var name: String
 //   var code: String              // Admin-vergeben
 //var imageName: String         // Asset-Name
 //   var isActive: Bool
 //   var createdAt: Date
    var email: String?

    
    // ✅ NEU: Location Data
      var addresse: String?
      var city: String?
      var postalCode: String?
      var latitude: Double?
      var longitude: Double?
      var telefon: String?
      var website: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade) var therapists: [User]?
    @Relationship(deleteRule: .cascade) var patients: [User]?
    
    
    // Computed Properties
      var coordinate: CLLocationCoordinate2D? {
          guard let lat = latitude, let lon = longitude else { return nil }
          return CLLocationCoordinate2D(
            latitude: lat, longitude: lon)
                }
                
                var fullAddress: String? {
                    guard let addresse = addresse, let postalCode = postalCode, let city = city else {
                        return nil
                    }
                    return "\(addresse), \(postalCode) \(city)"
                }
                
                init(
                    id: Int,
                  //  id: UUID = UUID(),
                    name: String,
                 //   code: String,
                //    imageName: String = "agil_placeholder",
                //    isActive: Bool = true,
                    email: String? = nil,
                    addresse: String? = nil,
                    city: String? = nil,
                    postalCode: String? = nil,
                    latitude: Double? = nil,
                    longitude: Double? = nil,
                    telefon: String? = nil,
                    website: String? = nil
                ) {
                    self.id = id
                    self.name = name
                  //  self.code = code
                  //  self.imageName = imageName
                 //   self.isActive = isActive
                //   self.createdAt = Date()
                    self.email = email
                    self.addresse = addresse
                    self.city = city
                    self.postalCode = postalCode
                    self.latitude = latitude
                    self.longitude = longitude
                    self.telefon = telefon
                    self.website = website
                }
                
                /// Maps Integration
                func openInMaps() {
                    guard let coordinate = coordinate else { return }
                    
                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                    mapItem.name = name
                    mapItem.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                    ])
                }
            }
    
  
