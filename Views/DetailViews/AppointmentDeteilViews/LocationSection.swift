//
//  LocationSection.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


// Features/Appointments/Presentation/Views/Components/LocationSection.swift
import SwiftUI
import MapKit
import SwiftData


struct LocationSection: View {
    let appointment: Appointment
    let showMap: Bool
    let region: MKCoordinateRegion
    
    @State private var showingFullMap = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Label("Ort", systemImage: "mappin.circle.fill")
                .font(.headline)
            
            // Location Name
            if let locationName = appointment.locationName {
                Text(locationName)
                    .font(.title3)
                    .fontWeight(.medium)
            }
            
            // Address
            if let address = appointment.locationAddress {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Map Preview
            if showMap, let coordinate = appointment.coordinate {
                Button(action: {
                    showingFullMap = true
                }) {
                    MapPreview(coordinate: coordinate, region: region)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                // Navigation Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        openInMaps(coordinate: coordinate)
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Apple Maps")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    if canOpenGoogleMaps() {
                        Button(action: {
                            openInGoogleMaps(coordinate: coordinate)
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                Text("Google Maps")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingFullMap) {
            if let coordinate = appointment.coordinate {
                FullMapView(
                    coordinate: coordinate,
                    locationName: appointment.locationName ?? "Termin-Ort",
                    address: appointment.locationAddress
                )
            }
        }
    }
    
    // MARK: - Navigation Helpers
    private func openInMaps(coordinate: CLLocationCoordinate2D) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = appointment.locationName ?? "Termin-Ort"
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func canOpenGoogleMaps() -> Bool {
        if let url = URL(string: "comgooglemaps://") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    private func openInGoogleMaps(coordinate: CLLocationCoordinate2D) {
        if let url = URL(string: "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving") {
            UIApplication.shared.open(url)
        }
    }
}
// MARK: - Map Preview Component (iOS 17+)
struct MapPreview: View {
    let coordinate: CLLocationCoordinate2D
    let region: MKCoordinateRegion
    
    @State private var position: MapCameraPosition
    
    init(coordinate: CLLocationCoordinate2D, region: MKCoordinateRegion) {
        self.coordinate = coordinate
        self.region = region
        _position = State(initialValue: .region(region))
    }
    
    var body: some View {
        Map(position: $position) {
            Marker("", coordinate: coordinate)
                .tint(.red)
        }
        .mapStyle(.standard)
        .disabled(true)
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .padding(12)
                }
            }
        )
    }
}
// MARK: - Full Map View (iOS 17+)
struct FullMapView: View {
    @Environment(\.dismiss) private var dismiss
    let coordinate: CLLocationCoordinate2D
    let locationName: String
    let address: String?
    
    @State private var position: MapCameraPosition
    
    init(coordinate: CLLocationCoordinate2D, locationName: String, address: String?) {
        self.coordinate = coordinate
        self.locationName = locationName
        self.address = address
        
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        _position = State(initialValue: .region(region))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $position) {
                    Annotation(locationName, coordinate: coordinate) {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .offset(y: -5)
                        }
                    }
                }
                .mapStyle(.standard)
                .ignoresSafeArea()
                
                // Location Info Card
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(locationName)
                            .font(.headline)
                        
                        if let address = address {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            openInMaps()
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Route")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "xmark")
                                Text("Schließen")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(
                    Color(.systemBackground)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(locationName)
                        .font(.headline)
                }
            }
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = locationName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
// MARK: - Preview
#Preview("Location Section - Mit Karte") {
    LocationSection(
        appointment: Appointment(
            date: Date().addingTimeInterval(86400),
            therapist: "Herr Leitsch",
            locationName: "Praxis Agil",
            locationAddress: "Juchostraße 7, 60385 Frankfurt am Main",
           
            locationLatitude: 50.1467,
            locationLongitude: 8.6346,
            emailUID: nil,
            status: .confirmed,
            userId: UUID(),        // ✅ Mock UUID
            praxisId: UUID()       // ✅ Mock UUID
        ),
        showMap: true,
        region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    .padding()
    .background(Color(.systemBackground))
}
#Preview("Location Section - Ohne Karte") {
    LocationSection(
        appointment: Appointment(
            date: Date().addingTimeInterval(86400),
            therapist: "Herr Leitsch",
            locationName: "Praxis Agil",
    
            locationAddress: "Juchostraße 7, 60385 Frankfurt am Main",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "Handtuch",
            emailUID: nil,
            status: .confirmed,
            userId: UUID(),        // ✅ Mock UUID
            praxisId: UUID()       // ✅ Mock UUID
        ),
        showMap: false,
        region: MKCoordinateRegion()
    )
    .padding()
    .background(Color(.systemBackground))
}
#Preview("Full Map View") {
    FullMapView(
        coordinate: CLLocationCoordinate2D(latitude: 50.1467, longitude: 8.6346,),
        locationName: "Praxis Agil",
        address: "Juchostraße 7, 60385 Frankfurt am Main"
    )
}
