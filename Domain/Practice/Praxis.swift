//
//  Praxis.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//

import Foundation

final class Praxis: @unchecked Sendable, Identifiable {
    var id: UUID
    var name: String
    var email: String?
    var addresse: String?
    var city: String?
    var postalCode: String?
    var latitude: Double?
    var longitude: Double?
    var telefon: String?
    var website: String?
    
    var fullAddress: String? {
        guard let addresse, let postalCode, let city else { return nil }
        return "\(addresse), \(postalCode) \(city)"
    }
    
    init(id: UUID = UUID(), name: String, email: String? = nil,
         addresse: String? = nil, city: String? = nil,
         postalCode: String? = nil, latitude: Double? = nil,
         longitude: Double? = nil, telefon: String? = nil,
         website: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.addresse = addresse
        self.city = city
        self.postalCode = postalCode
        self.latitude = latitude
        self.longitude = longitude
        self.telefon = telefon
        self.website = website
    }
}
