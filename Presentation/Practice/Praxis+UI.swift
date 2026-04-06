//
//  Praxis+UI.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//

import CoreLocation
import MapKit

extension Praxis {
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    func openInMaps() {
        guard let coordinate else { return }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let address = fullAddress.flatMap {
            MKAddress(fullAddress: $0, shortAddress: addresse)
        }
        let mapItem = MKMapItem(location: location, address: address)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
