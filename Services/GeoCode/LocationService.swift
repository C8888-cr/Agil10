//
//  LocationService.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  LocationService.swift
//  Agil7.0
//
//  Created by Christiane Roth on 07.10.25.
//

// Core/Services/LocationService.swift
import Foundation
import CoreLocation
import MapKit

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    // ✅ CLGeocoder entfernt – nicht mehr nötig
    
    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse ||
        authorizationStatus == .authorizedAlways
    }
    
    func geocode(address: String) async throws -> CLLocationCoordinate2D {
        guard let request = MKGeocodingRequest(addressString: address) else {
            throw LocationError.geocodingFailed
        }
        
        let items = try await request.mapItems
        
        guard let location = items.first?.location else {
            throw LocationError.geocodingFailed
        }
        return location.coordinate
    }
    
    // MARK: - Reverse Geocoding (Coordinates → Address)
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        guard let request = MKReverseGeocodingRequest(location: location) else {
            throw LocationError.reverseGeocodingFailed
        }
        
        let items = try await request.mapItems
        
        guard let item = items.first else {
            throw LocationError.reverseGeocodingFailed
        }
        
        // ✅ iOS 26: address statt placemark
        if let fullAddress = item.address?.fullAddress {
            return fullAddress
        }
        
        // Fallback: name des MapItems
        return item.name ?? ""
    }
    
    // MARK: - Search (unverändert – MKLocalSearch ist nicht deprecated)
    func search(query: String) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    }
}
    // MARK: - Helpers
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let number = placemark.subThoroughfare {
            if let last = components.last {
                components[components.count - 1] = "\(last) \(number)"
            }
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let zip = placemark.postalCode {
            if let city = components.last, components.count > 1 {
                components[components.count - 1] = "\(zip) \(city)"
            }
        }
        
        return components.joined(separator: ", ")
    }

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
}
// MARK: - Errors
enum LocationError: LocalizedError {
    case geocodingFailed
    case reverseGeocodingFailed
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .geocodingFailed:
            return "Adresse konnte nicht gefunden werden"
        case .reverseGeocodingFailed:
            return "Koordinaten konnten nicht in Adresse umgewandelt werden"
        case .unauthorized:
            return "Standort-Berechtigung fehlt"
        }
    }
}
