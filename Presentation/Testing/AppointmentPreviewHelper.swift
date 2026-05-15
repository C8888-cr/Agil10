import Foundation
import SwiftData
import MapKit
import Contacts

struct PreviewHelper {
    
    static func createModelContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(
            for: Appointment.self,
            configurations: config
        )
    }
    
    @MainActor
    static func createSessionManager() -> SessionManager {
        let container = try! ModelContainer(
            for: User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let userRepository = UserRepository(modelContext: context)
        let sessionManager = SessionManager(userRepository: userRepository)
        
        // Mock User setzen
        _ = userRepository.findOrCreate(
            firebaseUID: "preview-uid",
            email: "preview@example.com",
            firstName: "Max",
            lastName: "Mustermann"
        )
        sessionManager.setAuthenticatedUser(AuthUser(
            uid: "preview-uid",
            email: "preview@example.com",
            firstName: "Max",
            lastName: "Mustermann",
            praxisId: PraxisDataManager.praxis1Id
        ))
        
        return sessionManager
    }
    
    @MainActor
    static func createAppointmentViewModel() -> AppointmentViewModel {
        let container = createModelContainer()
        let context = ModelContext(container)
        let sessionManager = createSessionManager()
        
        let repository = AppointmentRepository(
            modelContext: context,
            session: sessionManager  // ← statt authService
        )
        
        let emailService = EmailService()
        let emailParser = EmailParserService(session: sessionManager)
        
        let addAppointmentUseCase = AddAppointmentUseCase(
            repository: repository,
            session: sessionManager  // ← statt authService
        )
        let updateAppointmentUseCase = UpdateAppointmentUseCase(    // 🆕
            repository: repository,
            calendarSync: nil  // im Preview kein Calendar-Sync nötig
        )
        
        let detectChangesUseCase = DetectAppointmentChangesUseCase(
            repository: repository
        )
        
        let sampleAppointments = createSampleAppointments()
        for appointment in sampleAppointments {
            context.insert(appointment)
        }
        try? context.save()
        
        return AppointmentViewModel(
            modelContext: context,
            session: sessionManager,  // ← neu
            repository: repository,
            emailParser: emailParser,
            detectAppointmentChangesUseCase: detectChangesUseCase,
            cancelAppointmentUseCase: CancelAppointmentUseCase(
                repository: repository,
                emailService: emailService
            ),
            addAppointmentUseCase: addAppointmentUseCase,
            updateAppointmentUseCase: updateAppointmentUseCase,
            emailService: emailService,
            markAsNotifiedUseCase: MarkAsNotifiedUseCase(
                repository: repository
            ),
            loadAppointmentsUseCase: LoadAppointmentsUseCase(
                repository: repository
            ),
            deleteAppointmentUseCase: DeleteAppointmentUseCase(
                repository: repository
            ),
            parseAppointmentsFromEmailUseCase: ParseAppointmentsFromEmailUseCase(
                repository: repository,
                emailParser: emailParser,
                detectChangesUseCase: detectChangesUseCase
            )
        )
    }
    

    static func createSampleAppointments() -> [Appointment] {
        let mockUserId = UUID()
        
        return [
            Appointment(
                date: Date().addingTimeInterval(86400),
                therapist: "Dr. Schmidt",
                locationName: "Therapie-Praxis Mitte",
                locationAddress: "Unter den Linden 1, 10117 Berlin",
                locationLatitude: 52.520008,
                locationLongitude: 13.404954,
                notes: "Bitte 10 Minuten früher kommen",
                emailUID: nil,
                status: .confirmed,
                userId: mockUserId,
                praxisId: UUID()
            ),
            Appointment(
                date: Date().addingTimeInterval(172800),
                therapist: "Frau Müller",
                locationName: "Physiotherapie Nord",
                locationAddress: "Hauptstraße 42, 12345 Berlin",
                locationLatitude: 52.530000,
                locationLongitude: 13.415000,
                notes: nil,
                emailUID: nil,
                status: .confirmed,
                userId: mockUserId,
                praxisId: UUID()
            ),
            Appointment(
                date: Date().addingTimeInterval(-86400),
                therapist: "Herr Weber",
                locationName: nil,
                locationAddress: nil,
                locationLatitude: nil,
                locationLongitude: nil,
                notes: "Termin wurde abgesagt",
                emailUID: nil,
                status: .cancelled,
                userId: mockUserId,
                praxisId: UUID()
            )
        ]
    }
    
    // ✅ RAUS aus createSampleAppointments!
    static func createSampleMapItems() -> [MKMapItem] {
        let items: [MKMapItem] = [
            createMapItem(
                name: "Therapie-Praxis Mitte",
                street: "Unter den Linden",
                number: "1",
                zip: "10117",
                city: "Berlin",
                latitude: 52.520008,
                longitude: 13.404954
            ),
            createMapItem(
                name: "Physiotherapie Nord",
                street: "Hauptstraße",
                number: "42",
                zip: "12345",
                city: "Berlin",
                latitude: 52.530000,
                longitude: 13.415000
            ),
            createMapItem(
                name: "Gesundheitszentrum Süd",
                street: "Bergstraße",
                number: "15",
                zip: "10963",
                city: "Berlin",
                latitude: 52.500000,
                longitude: 13.400000
            )
        ]
        
        return items
    }
    
    // ✅ PRIVATE Helper – iOS 26 MKAddress API
    // ✅ PRIVATE Helper – iOS 26 MKAddress API
    private static func createMapItem(
        name: String,
        street: String,
        number: String,
        zip: String,
        city: String,
        latitude: Double,
        longitude: Double
    ) -> MKMapItem {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        let address = MKAddress(
            fullAddress: "\(street) \(number), \(zip) \(city)",
            shortAddress: "\(street) \(number)"
        )
        
        let mapItem = MKMapItem(location: location, address: address)
        mapItem.name = name
        return mapItem
    }
}
