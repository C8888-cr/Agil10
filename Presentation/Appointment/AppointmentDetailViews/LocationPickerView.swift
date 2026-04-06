//
//  LocationPickerView.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  LocationPickerView.swift
//  Agil7.0
//
//  Created by Christiane Roth on 07.10.25.
//

// Features/Appointments/Presentation/Views/LocationPickerView.swift
import SwiftUI
import MapKit
import SwiftData

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationService = LocationService()
    
    @Binding var locationName: String
    @Binding var locationAddress: String
    @Binding var coordinate: CLLocationCoordinate2D?
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedLocation: MKMapItem?
    @State private var isSearching = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                
                // ✅ iOS 17+ Map API
                Map(position: .constant(.region(region))) {
                    ForEach(searchResults, id: \.self) { item in
                        Marker(
                            item.name ?? "Ort",
                            coordinate: item.location.coordinate
                        )
                        .tint(.blue)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                if !searchResults.isEmpty {
                    resultsList
                }
            }
            .navigationTitle("Ort auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        saveLocation()
                    }
                    .disabled(selectedLocation == nil)
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Adresse suchen...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit {
                    performSearch()
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults, id: \.self) { item in
                    LocationResultRow(
                        item: item,
                        isSelected: selectedLocation == item
                    )
                    .onTapGesture {
                        selectLocation(item)
                    }
                    
                    Divider()
                }
            }
        }
        .frame(maxHeight: 300)
        .background(Color(.systemBackground))
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        
        Task {
            do {
                searchResults = try await locationService.search(query: searchText)
                isSearching = false
            } catch {
                print("Search error: \(error)")
                isSearching = false
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        selectedLocation = item
        region.center = item.location.coordinate
        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    }
    
    private func saveLocation() {
        guard let item = selectedLocation else { return }
        
        locationName = item.name ?? ""
        locationAddress = item.address?.fullAddress ?? ""
        coordinate = item.location.coordinate
        
        dismiss()
    }
    
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
        if let zip = placemark.postalCode, let city = placemark.locality {
            components.append("\(zip) \(city)")
        }
        
        return components.joined(separator: ", ")
    }
}

// MARK: - Location Result Row
struct LocationResultRow: View {
    let item: MKMapItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(isSelected ? Color.blue : Color.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Unbekannt")
                    .font(.headline)
                
                if let address = formatAddress() {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .contentShape(Rectangle())
    }
    
    private func formatAddress() -> String? {
        // ✅ MKAddress direkt nutzen
        if let full = item.address?.fullAddress {
            return full
        }
        return item.name
    }
}
// MARK: - Previews
#Preview("Location Picker - Leer") {
    @Previewable @State var locationName = ""
    @Previewable @State var locationAddress = ""
    @Previewable @State var coordinate: CLLocationCoordinate2D? = nil
    
    LocationPickerView(
        locationName: $locationName,
        locationAddress: $locationAddress,
        coordinate: $coordinate
    )
}
#Preview("Location Picker - Mit Auswahl") {
    @Previewable @State var locationName = "Therapie-Praxis Mitte"
    @Previewable @State var locationAddress = "Unter den Linden 1, 10117 Berlin"
    @Previewable @State var coordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(
        latitude: 52.520008,
        longitude: 13.404954
    )
    
    LocationPickerView(
        locationName: $locationName,
        locationAddress: $locationAddress,
        coordinate: $coordinate
    )
}
#Preview("Location Result Row - Ausgewählt") {
    let items = PreviewHelper.createSampleMapItems()
    
    VStack(spacing: 0) {
        LocationResultRow(
            item: items[0],
            isSelected: true
        )
        Divider()
        
        LocationResultRow(
            item: items[1],
            isSelected: false
        )
        Divider()
        
        LocationResultRow(
            item: items[2],
            isSelected: false
        )
    }
    .padding()
}
#Preview("Location Results List") {
    ScrollView {
        LazyVStack(spacing: 0) {
            ForEach(PreviewHelper.createSampleMapItems(), id: \.self) { item in
                LocationResultRow(
                    item: item,
                    isSelected: item.name == "Therapie-Praxis Mitte"
                )
                Divider()
            }
        }
    }
    .frame(maxHeight: 300)
}
