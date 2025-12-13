//
//  AddAppointmentSheetViewModel.swift
//  Agil
//
//  Created by Christiane Roth on 03.12.25.
//

import SwiftUI
import SwiftData
import CoreLocation

@MainActor


class AddAppointmentViewModel: ObservableObject {
    @Published var date = Date()
    @Published var therapist = ""
    @Published var locationName = ""
    @Published var locationAddress = ""
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var notes = ""
    @Published var showingLocationPicker = false
    
    private let appointmentViewModel: AppointmentViewModel
    
    init(appointmentViewModel: AppointmentViewModel) {
        self.appointmentViewModel = appointmentViewModel
    }
    
    
    
    // ✅ Computed Properties
private var hasLocation: Bool {
    !locationName.isEmpty || !locationAddress.isEmpty || coordinate != nil
}

    var canSave: Bool { !therapist.isEmpty }
    
    
// ✅ Actions
private func clearLocation() {
    locationName = ""
    locationAddress = ""
    coordinate = nil
}

 func saveAppointment() async {
    let appointment = Appointment(
        date: date,
        therapist: therapist,
        locationName: locationName.isEmpty ? nil : locationName,
        locationAddress: locationAddress.isEmpty ? nil : locationAddress,
        locationLatitude: coordinate?.latitude,
        locationLongitude: coordinate?.longitude,
        notes: notes.isEmpty ? nil : notes
        // user: ist OPTIONAL - wird nicht angegeben!
    )
    
     await appointmentViewModel.addAppointment(appointment)
    

    }
}

