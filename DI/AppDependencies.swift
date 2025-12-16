//
//  AppDependencies.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  AppDependencies.swift
//  Agil7.0
//
//  Created by Christiane Roth on 07.10.25.
//

// Core/DI/AppDependencies.swift
import Foundation
import SwiftData

/*
@MainActor


class AppDependencies {
    
    static let shared = AppDependencies()
    
    
    
    // MARK: - Core
    let modelContainer: ModelContainer  // ✅ Für später
    let modelContext: ModelContext      // ✅ Für jetzt
    
    //  let locationService: LocationService
    
    // Repositories
    let appointmentRepository: AppointmentRepository
    
    // Services
    let emailParser: EmailParserService
    let emailService: EmailService
    
    // UseCases
    let addAppointmentUseCase: AddAppointmentUseCase
    let deleteAppointmentUseCase: DeleteAppointmentUseCase
    let cancelAppointmentUseCase: CancelAppointmentUseCase
    let parseEmailUseCase: ParseEmailUseCase
    let detectAppointmentChangesUseCase: DetectAppointmentChangesUseCase
    let markAsNotifiedUseCase: MarkAsNotifiedUseCase
    let loadAppointmentsUseCase: LoadAppointmentsUseCase
    let parseAppointmentsFromEmailUseCase: ParseAppointmentsFromEmailUseCase
    
    // ViewModels
    private(set) var appointmentViewModel: AppointmentViewModel!
    
    private init() {
        
        // 1. Container & Context
        self.modelContainer = PersistenceController.shared.container
        self.modelContext = self.modelContainer.mainContext
        
        // Services
        //    self.locationService = LocationService()
        
        // Repositories
        self.appointmentRepository = AppointmentRepository(modelContext: modelContext)
        
        // Services
        self.emailParser = EmailParserService()
        self.emailService = EmailService()
        
        // UseCases
        self.addAppointmentUseCase = AddAppointmentUseCase(repository: appointmentRepository)
        self.deleteAppointmentUseCase = DeleteAppointmentUseCase(repository: appointmentRepository)
        self.cancelAppointmentUseCase = CancelAppointmentUseCase(
            repository: appointmentRepository,
            emailService: emailService
        )
        self.parseEmailUseCase = ParseEmailUseCase(parser: emailParser)
        self.detectAppointmentChangesUseCase = DetectAppointmentChangesUseCase(repository: appointmentRepository)
        self.markAsNotifiedUseCase = MarkAsNotifiedUseCase(repository: appointmentRepository)
        self.loadAppointmentsUseCase = LoadAppointmentsUseCase(repository: appointmentRepository)
        self.parseAppointmentsFromEmailUseCase = ParseAppointmentsFromEmailUseCase(
            repository: appointmentRepository,
            emailParser: emailParser,
            detectChangesUseCase: detectAppointmentChangesUseCase
        )
        
        // ViewModel
        self.appointmentViewModel = AppointmentViewModel(
            repository: appointmentRepository,
            emailParser: emailParser,
            detectAppointmentChangesUseCase: detectAppointmentChangesUseCase,
            cancelAppointmentUseCase: cancelAppointmentUseCase,
            addAppointmentUseCase: addAppointmentUseCase,
            emailService: emailService,
            markAsNotifiedUseCase: markAsNotifiedUseCase,
            loadAppointmentsUseCase: loadAppointmentsUseCase,
            parseEmailUseCase: parseEmailUseCase,
            deleteAppointmentUseCase: deleteAppointmentUseCase,
            parseAppointmentsFromEmailUseCase: parseAppointmentsFromEmailUseCase
        )
    }
   
}
*/

@MainActor
class AppDependencies {
    static let shared = AppDependencies()
    
    // MARK: - Core
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    let authService: AuthServiceProtocol  // ← NEU!
    
    // MARK: - AppState (LAZY)
    // LAZY - jetzt korrekt!
       lazy var appState = AppState(
           modelContext: modelContext,  // ✅
           authService: authService     // ✅
       )
    
    
    // MARK: - Repositories (LAZY)
    lazy var appointmentRepository = AppointmentRepository(modelContext: modelContext)
    lazy var videoRepository = VideoRepository(modelContext: modelContext)
    
    // MARK: - Services
    let emailParser: EmailParserService
    let emailService: EmailService
    
    // MARK: - UseCases (LAZY)
    lazy var addAppointmentUseCase = AddAppointmentUseCase(repository: appointmentRepository)
    lazy var deleteAppointmentUseCase = DeleteAppointmentUseCase(repository: appointmentRepository)
    lazy var cancelAppointmentUseCase = CancelAppointmentUseCase(
        repository: appointmentRepository,
        emailService: emailService
    )
    lazy var parseEmailUseCase = ParseEmailUseCase(parser: emailParser)
    lazy var detectAppointmentChangesUseCase = DetectAppointmentChangesUseCase(repository: appointmentRepository)
    lazy var markAsNotifiedUseCase = MarkAsNotifiedUseCase(repository: appointmentRepository)
    lazy var loadAppointmentsUseCase = LoadAppointmentsUseCase(repository: appointmentRepository)
    lazy var parseAppointmentsFromEmailUseCase = ParseAppointmentsFromEmailUseCase(
        repository: appointmentRepository,
        emailParser: emailParser,
        detectChangesUseCase: detectAppointmentChangesUseCase
    )
    
    // MARK: - ViewModels (LAZY)
    lazy var appointmentViewModel = AppointmentViewModel(
        repository: appointmentRepository,
        emailParser: emailParser,
        detectAppointmentChangesUseCase: detectAppointmentChangesUseCase,
        cancelAppointmentUseCase: cancelAppointmentUseCase,
        addAppointmentUseCase: addAppointmentUseCase,
        emailService: emailService,
        markAsNotifiedUseCase: markAsNotifiedUseCase,
        loadAppointmentsUseCase: loadAppointmentsUseCase,
        parseEmailUseCase: parseEmailUseCase,
        deleteAppointmentUseCase: deleteAppointmentUseCase,
        parseAppointmentsFromEmailUseCase: parseAppointmentsFromEmailUseCase
    )
    
    private init() {
        // 1. AUTH SWITCH (Oben!)
        #if DEBUG
        self.authService = MockAuthService()
        #else
        self.authService = RealAuthService()
        #endif
        
        // 2. SwiftData
        self.modelContainer = PersistenceController.shared.container
        self.modelContext = modelContainer.mainContext
        
        // 3. Services (nicht lazy - leichtgewichtig)
        self.emailParser = EmailParserService()
        self.emailService = EmailService()
    }
}
