

// Core/DI/AppDependencies.swift
import Foundation
import SwiftData


@MainActor
class AppDependencies {
    static let shared = AppDependencies()
    
    // MARK: - Core
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    let authService: AuthService//Protocol
 

    // MARK: - Services
    let emailParser: EmailParserService
    let emailService: EmailService
    
    
    
    // MARK: - Repositories (LAZY)
    // ✅ NEU (Fix 1)
    lazy var appointmentRepository = AppointmentRepository(
        modelContext: modelContext,
        authService: authService  // ← AuthService statt userId!        return AppointmentRepository(modelContext: modelContext, userId: userId)
    )
    
    
    // ✅ NACHHER (computed property = immer gleicher Context!):
    var videoRepository: VideoRepository {
        VideoRepository(
            modelContext: modelContext,  // ← IMMER der gleiche!
            storageService: .shared,
            thumbnailService: .shared
        )
    }
    var videoLibraryVM: VideoLibraryViewModel {
        VideoLibraryViewModel(
            repository: videoRepository,
            modelContext: modelContext,  // ← IMMER der gleiche!
            storageService: .shared
        )
    }
    

    
    // MARK: - AppointmentUseCases (LAZY)
    lazy var addAppointmentUseCase = AddAppointmentUseCase(repository: appointmentRepository, authService: authService)
    lazy var deleteAppointmentUseCase = DeleteAppointmentUseCase(repository: appointmentRepository)
    lazy var cancelAppointmentUseCase = CancelAppointmentUseCase(
        repository: appointmentRepository,
        emailService: emailService)
 //   lazy var parseEmailUseCase = ParseEmailUseCase(parser: emailParser)
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
        modelContext: modelContext,
        repository: appointmentRepository,
        emailParser: emailParser,
        detectAppointmentChangesUseCase: detectAppointmentChangesUseCase,
        cancelAppointmentUseCase: cancelAppointmentUseCase,
        addAppointmentUseCase: addAppointmentUseCase,
        emailService: emailService,
        markAsNotifiedUseCase: markAsNotifiedUseCase,
        loadAppointmentsUseCase: loadAppointmentsUseCase,
    //    parseEmailUseCase: parseEmailUseCase,
        deleteAppointmentUseCase: deleteAppointmentUseCase,
        parseAppointmentsFromEmailUseCase: parseAppointmentsFromEmailUseCase
    )
    
    lazy var calendarViewModel = CalendarViewModel(modelContext: modelContext)
    
    lazy var progressViewModel = ProgressViewModel(modelContext: modelContext)
    
    lazy var settingsViewModel = SettingsViewModel(modelContext: modelContext,
    authService:authService)
    
    lazy var profileViewModel = ProfileViewModel(modelContext: modelContext, authService: authService)
    
 //   lazy var trainingViewModel = TrainingViewModel()
    





  


    

    
    // Core/DI/AppDependencies.swift
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
              modelContext: modelContext  // ✅ Context übergeben!
          )
          #else
          self.authService = AuthService(
              authServiceProtocol: RealAuthService(),
              modelContext: modelContext  // ✅ Auch hier!
          )
        print("✅ RealAuthService erstellt")
        #endif
        
        // 3. Services (nicht lazy - leichtgewichtig)
        self.emailParser = EmailParserService()
        self.emailService = EmailService()
    }
  }
