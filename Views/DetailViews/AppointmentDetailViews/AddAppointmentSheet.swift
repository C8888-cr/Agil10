//
//  AddAppointmentSheet.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  AddAppointmentSheet.swift
//  Agil7.0
//
//  Created by Christiane Roth on 07.10.25.
//

// Features/Appointments/Presentation/Views/AddAppointmentSheet.swift
import SwiftUI
import SwiftData
import CoreLocation
struct AddAppointmentSheet: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppointmentViewModel
    
    @State private var date = Date()
    @State private var therapist = ""
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var notes = ""
    @State private var showingLocationPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Termin Details") {
                    DatePicker(
                        "Datum & Zeit",
                        selection: $date,
                        in: Date()...
                    )
                    
                    TextField("Therapeut*in", text: $therapist)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                }
                
                Section("Ort") {
                    if hasLocation {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    if !locationName.isEmpty {
                                        Text(locationName)
                                            .font(.headline)
                                    }
                                    
                                    if !locationAddress.isEmpty {
                                        Text(locationAddress)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    clearLocation()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    Button {
                        showingLocationPicker = true
                    } label: {
                        Label(
                            hasLocation ? "Ort ändern" : "Ort hinzufügen",
                            systemImage: hasLocation ? "map" : "map.fill"
                        )
                    }
                }
                
                Section("Notizen") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Neuer Termin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task {
                        await saveAppointment()
                        }
                    }
                    .disabled(therapist.isEmpty)
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(
                    locationName: $locationName,
                    locationAddress: $locationAddress,
                    coordinate: $coordinate
                )
            }
            .alert("Fehler", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {
                    viewModel.clearErrors()
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // ✅ Computed Properties
    private var hasLocation: Bool {
        !locationName.isEmpty || !locationAddress.isEmpty || coordinate != nil
    }
    
    private var errorMessage: String {
        if let error = viewModel.validationError {
            return error.errorDescription ?? "Validierungsfehler"
        } else if let error = viewModel.currentError {
            return error.localizedDescription
        } else {
            return "Ein unbekannter Fehler ist aufgetreten"
        }
    }
    
    // ✅ Actions
    private func clearLocation() {
        locationName = ""
        locationAddress = ""
        coordinate = nil
    }
    
    private func saveAppointment() async {
        // ✅ NUR 10 Zeilen! Pure UI!
        await viewModel.addAppointmentManual(
            date: date,
            therapist: therapist,
            locationName: locationName.isEmpty ? nil : locationName,
            locationAddress: locationAddress.isEmpty ? nil : locationAddress,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            notes: notes.isEmpty ? nil : notes
        )
        
        if !viewModel.showingError {
            dismiss()
        }
    }

}
#Preview {
    AddAppointmentSheet()
        .environmentObject(AppDependencies.shared.appointmentViewModel)
}
