//
//  PreviewHelper.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


// Features/Appointments/Presentation/Helpers/PreviewHelper.swift
import Foundation
import SwiftData
import MapKit
import Contacts


struct PreviewHelper {
    
    // ✅ In-Memory ModelContainer (wird nicht gespeichert)
    static func createModelContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Appointment.self,
            configurations: config
        )
        return container
    }
    
    // ✅ ViewModel mit Mock-Daten
    @MainActor static func createAppointmentViewModel() -> AppointmentViewModel {

        let container = createModelContainer()
        let context = ModelContext(container)
        let repository = AppointmentRepository(modelContext: context, userId: UUID())
        let emailService = EmailService()
        let emailParser = EmailParserService()
        
        // Optional: Sample-Daten einfügen
        let sampleAppointments = createSampleAppointments()
        for appointment in sampleAppointments {
            context.insert(appointment)
        }
        try? context.save()
        
        return AppointmentViewModel(
                  repository: repository,
                  emailParser: emailParser,
                  detectAppointmentChangesUseCase: DetectAppointmentChangesUseCase(
                      repository: repository
                  ),
                  cancelAppointmentUseCase: CancelAppointmentUseCase(
                      repository: repository,
                      emailService: emailService
                  ),
                  addAppointmentUseCase: AddAppointmentUseCase(
                      repository: repository,
                      authService: AuthService(authServiceProtocol: MockAuthService()))
                  ,
                  emailService: emailService,
                  markAsNotifiedUseCase: MarkAsNotifiedUseCase(
                      repository: repository
                  ),
                  loadAppointmentsUseCase: LoadAppointmentsUseCase(
                      repository: repository
                  ),
                  parseEmailUseCase: ParseEmailUseCase(
                      parser: emailParser
                  ),
                  deleteAppointmentUseCase: DeleteAppointmentUseCase(
                      repository: repository
                  ),
                  parseAppointmentsFromEmailUseCase: ParseAppointmentsFromEmailUseCase(
                    repository: repository, emailParser: emailParser,  // ✅ Hinzugefügt
                    detectChangesUseCase: DetectAppointmentChangesUseCase(
                        repository: repository
                    )
                  )
              )
          }
    
    // ✅ Beispiel-Termine für Previews
    static func createSampleAppointments() -> [Appointment] {
        return [
            Appointment(
                date: Date().addingTimeInterval(86400), // Morgen
                therapist: "Dr. Schmidt",
                locationName: "Therapie-Praxis Mitte",
                locationAddress: "Unter den Linden 1, 10117 Berlin",
                locationLatitude: 52.520008,
                locationLongitude: 13.404954,
                notes: "Bitte 10 Minuten früher kommen",
                emailUID: nil,
                status: .confirmed,
                userId: UUID(),        // ✅ Mock UUID
                praxisId: UUID()
            ),
            Appointment(
                date: Date().addingTimeInterval(172800), // Übermorgen
                therapist: "Frau Müller",
                locationName: "Physiotherapie Nord",
                locationAddress: "Hauptstraße 42, 12345 Berlin",
                locationLatitude: 52.530000,
                locationLongitude: 13.415000,
                notes: nil,
                emailUID: nil,
                status: .confirmed,
                userId: UUID(),        // ✅ Mock UUID
                praxisId: UUID()
       
            ),
            Appointment(
                date: Date().addingTimeInterval(-86400), // Gestern
                therapist: "Herr Weber",
                locationName: nil,
                locationAddress: nil,
                locationLatitude: nil,
                locationLongitude: nil,
                notes: "Termin wurde abgesagt",
                emailUID: nil,
                status: .cancelled,
                userId: UUID(),        // ✅ Mock UUID
                praxisId: UUID() 
            )
        ]
    }
}
extension PreviewHelper {
    
    // ✅ Sample MKMapItems für Location-Previews
    static func createSampleMapItems() -> [MKMapItem] {
        let locations = [
            (name: "Therapie-Praxis Mitte", lat: 52.520008, lon: 13.404954, street: "Unter den Linden 1", city: "Berlin", zip: "10117"),
            (name: "Physiotherapie Nord", lat: 52.530000, lon: 13.415000, street: "Hauptstraße 42", city: "Berlin", zip: "12345"),
            (name: "Reha-Zentrum Süd", lat: 52.500000, lon: 13.400000, street: "Parkstraße 15", city: "Berlin", zip: "10115"),
            (name: "Ergotherapie West", lat: 52.510000, lon: 13.390000, street: "Bahnhofstraße 8", city: "Berlin", zip: "10178")
        ]
        
        return locations.map { location in
            let coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon)
            let placemark = MKPlacemark(
                coordinate: coordinate,
                addressDictionary: [
                    CNPostalAddressStreetKey: location.street,
                    CNPostalAddressCityKey: location.city,
                    CNPostalAddressPostalCodeKey: location.zip
                ]
            )
            
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = location.name
            return mapItem
        }
    }
}
extension PreviewHelper {
    
    static func createSampleUser() -> User {
        return User(
            id: UUID(),
            email: "test@example.com",
            passwordHash: "hashedPassword123", role: .patient
        )
    }
}
 

extension PreviewHelper {
    
    // ✅ Video Repository für Preview
    static func createVideoRepository() -> VideoRepositoryMock {
        return VideoRepositoryMock()
    }
}
    // ✅ Model Container für SwiftData

// ✅ MOCK VIDEO REPOSITORY - VEREINFACHT
class VideoRepositoryMock: VideoRepositoryProtocol {
    
    private var mockVideos: [Video] = []
    
    init() {
        // Starte mit leeren Videos - keine Sample-Daten!
        self.mockVideos = []
    }
    
    // MARK: - Protocol Implementation
    func createVideo(metadata: Video) async throws {
        mockVideos.append(metadata)
    }
    
    func fetchAllVideos(for user: User) async throws -> [Video] {
        mockVideos
    }
    
    func fetchAllVideos() async throws -> [Video] {
        mockVideos
    }
    
    func fetchVideo(by id: UUID) async throws -> Video? {
        mockVideos.first { $0.id == id }
    }
    
    func updateVideo(metadata: Video) async throws {
        if let index = mockVideos.firstIndex(where: { $0.id == metadata.id }) {
            mockVideos[index] = metadata
        }
    }
    
    func deleteVideo(metadata: Video) async throws {
        mockVideos.removeAll { $0.id == metadata.id }
    }
    
    func toggleFavorite(metadata: Video) async throws { }
    func updateLastUsed(metadata: Video) async throws { }
    
    func fetchFilteredVideos(
        category: ExerciseCategory?,
        bodyRegion: BodyRegion?,
        equipment: Equipment?,
        searchText: String?,
        favoritesOnly: Bool,
        for user: User
    ) async throws -> [Video] {
        mockVideos
    }
    
    func uploadVideo(
        from sourceURL: URL,
        title: String,
        category: ExerciseCategory,
        bodyRegion: BodyRegion,
        equipment: Equipment,
        defaultRepetitions: Int,
        defaultPauseSeconds: Int,
        loopDurationSeconds: Int?,
        for user: User
    ) async throws -> Video {
        fatalError("uploadVideo not implemented in mock")
    }
    
    func fetchVideosByCategory(_ category: String) async throws -> [Video] {
        mockVideos
    }
    
    func searchVideos(query: String) async throws -> [Video] {
        mockVideos
    }
}
