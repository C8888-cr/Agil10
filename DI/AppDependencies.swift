

// Core/DI/AppDependencies.swift
import Foundation
import SwiftData


@MainActor
class AppDependencies: ObservableObject {
    static let shared = AppDependencies()
    
    // MARK: - Core
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    let authService: AuthService
 

    // MARK: - Services
    let emailParser: EmailParserService
    let emailService: EmailService
    
    
    // MARK: - Repositories (LAZY)
    lazy var appointmentRepository = AppointmentRepository(
        modelContext: modelContext,
        authService: authService
    )
    
    lazy var videoRepository = VideoRepository (
            modelContext: modelContext,
            storageService: .shared,
            thumbnailService: .shared
        )
    
 
    
    // MARK: - AppointmentUseCases
    lazy var addAppointmentUseCase = AddAppointmentUseCase(
        repository: appointmentRepository,
        authService: authService
    )
    lazy var deleteAppointmentUseCase = DeleteAppointmentUseCase(
        repository: appointmentRepository
    )
    lazy var cancelAppointmentUseCase = CancelAppointmentUseCase(
        repository: appointmentRepository,
        emailService: emailService
    )
    lazy var detectAppointmentChangesUseCase = DetectAppointmentChangesUseCase(
        repository: appointmentRepository
    )
    lazy var markAsNotifiedUseCase = MarkAsNotifiedUseCase(
        repository: appointmentRepository
    )
    lazy var loadAppointmentsUseCase = LoadAppointmentsUseCase(
        repository: appointmentRepository
    )
    lazy var parseAppointmentsFromEmailUseCase = ParseAppointmentsFromEmailUseCase(
        repository: appointmentRepository,
        emailParser: emailParser,
        detectChangesUseCase: detectAppointmentChangesUseCase
    )
    
    
    
    
    
    
    // MARK: - ViewModels (LAZY)
    lazy var progressViewModel = ProgressViewModel(
           modelContext: modelContext,
           authService: authService
       )

    lazy var appointmentViewModel = AppointmentViewModel(
        modelContext: modelContext,
        repository: appointmentRepository,
        emailParser: emailParser,
        detectAppointmentChangesUseCase: detectAppointmentChangesUseCase,
        cancelAppointmentUseCase: cancelAppointmentUseCase,
        addAppointmentUseCase: addAppointmentUseCase,
        emailService: emailService,
        markAsNotifiedUseCase: markAsNotifiedUseCase,
        loadAppointmentsUseCase: loadAppointmentsUseCase,
        deleteAppointmentUseCase: deleteAppointmentUseCase,
        parseAppointmentsFromEmailUseCase: parseAppointmentsFromEmailUseCase
    )
    
    lazy var calendarViewModel = CalendarViewModel(
           progressViewModel: progressViewModel,
           authService: authService
       )
    
    lazy var videoLibraryVM =
        VideoLibraryViewModel(
            repository: videoRepository,
            modelContext: modelContext,
            authService: authService
        )
    

    lazy var settingsViewModel = SettingsViewModel(
        modelContext: modelContext,
        authService: authService
    )
    
    lazy var profileViewModel = ProfileViewModel(
        modelContext: modelContext,
        authService: authService
    )
    

    // MARK: - Init
    private init() {
        // 1. SwiftData ZUERST
        self.modelContainer = PersistenceController.shared.container
        self.modelContext = modelContainer.mainContext
        
        print("✅ AppDependencies.init()")
        print("   ModelContext: \(modelContext)")
        
        // 2. AUTH SERVICE erstellen (Mock/Real Switch)
        #if DEBUG
        let mockService = MockAuthService(modelContext: modelContext)
          self.authService = AuthService(
              authServiceProtocol: mockService,
              modelContext: modelContext
          )
          #else
          self.authService = AuthService(
              authServiceProtocol: RealAuthService(),
              modelContext: modelContext
          )
        print("✅ RealAuthService erstellt")
        #endif
        
        // 3. Services (nicht lazy - leichtgewichtig)
        self.emailParser = EmailParserService()
        self.emailService = EmailService()
    }
  }
