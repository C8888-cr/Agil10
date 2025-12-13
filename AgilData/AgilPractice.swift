//
//  AgilPractice.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//

import Foundation
import CoreLocation
struct PracticeLocations {
    
    // MARK: - Adressen
    
    static let agilEschersheim = PracticeLocation(
        id: "eschersheim",
        name: "agil Eschersheim",
        address: "Kirchhainer Straße 29",
        postalCode: "60433",
        city: "Frankfurt Eschersheim",
        phone: "069 95108770",
        email: "agil-eschersheim@physio-agil.de",
        latitude: 50.1515,
        longitude: 8.6547
    )
    
    static let agilPreungesheim = PracticeLocation(
        id: "preungesheim",
        name: "agil Preungesheim",
        address: "Kantapfelstraße 26",
        postalCode: "60435",
        city: "Frankfurt Preungesheim",
        phone: "069 95407666",
        email: "agil-preungesheim@physio-agil.de",
        latitude: 50.1467,
        longitude: 8.7021
    )
    
    static let agilLangen = PracticeLocation(
        id: "langen",
        name: "agil Langen",
        address: "Bahnstraße 37",
        postalCode: "63225",
        city: "Langen",
        phone: "06103 2086030",
        email: "langen@physio-agil.de",
        latitude: 49.9929,
        longitude: 8.6683
    )
    
    static let agilOstend = PracticeLocation(
        id: "ostend",
        name: "agil Ostend",
        address: "Juchostraße 7",
        postalCode: "60385",
        city: "Frankfurt Ostend",
        phone: "069 449693",
        email: "agil-ostend@physio-agil.de",
        latitude: 50.1088,
        longitude: 8.7142
    )
    
    static let agilDornbusch = PracticeLocation(
        id: "dornbusch",
        name: "agil Dornbusch",
        address: "Eschersheimer Landstraße 311",
        postalCode: "60320",
        city: "Frankfurt Dornbusch",
        phone: "069 94598465",
        email: "agil-dornbusch@physio-agil.de",
        latitude: 50.1389,
        longitude: 8.6625
    )
    
    static let agilAltEschersheim = PracticeLocation(
        id: "alt-eschersheim",
        name: "agil Alt-Eschersheim",
        address: "Alt-Eschersheim 34",
        postalCode: "60433",
        city: "Frankfurt Alt-Eschersheim",
        phone: "069 577662",
        email: "agil-alt-eschersheim@physio-agil.de",
        latitude: 50.1496,
        longitude: 8.6502
    )
    
    static let agilChiropraktik = PracticeLocation(
        id: "chiropraktik",
        name: "agil Chiropraktik",
        address: "Alt-Eschersheim 34",
        postalCode: "60433",
        city: "Frankfurt Alt-Eschersheim",
        phone: "069 71718668",
        email: "chiropraktik@physio-agil.de",
        latitude: 50.1496,
        longitude: 8.6502
    )
    
    // MARK: - Liste aller Praxen
    
    static let all: [PracticeLocation] = [
        agilEschersheim,
        agilPreungesheim,
        agilLangen,
        agilOstend,
        agilDornbusch,
        agilAltEschersheim,
        agilChiropraktik
    ]
    // MARK: - Helper
    static var current: PracticeLocation {
        agilOstend  // Erstmal fest auf Ostend
    }
}
// MARK: - Model
struct PracticeLocation: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let postalCode: String
    let city: String
    let phone: String
    let email: String
    let latitude: Double
    let longitude: Double
    
    var fullAddress: String {
        "\(address), \(postalCode) \(city)"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
