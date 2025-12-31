

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
    var appointmentRepository: AppointmentRepository {  // lazy → var
        let userId = authService.currentUser?.id ?? MockAuthService.mockPatientId
        return AppointmentRepository(modelContext: modelContext, userId: userId)
    }
    
    
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
    
    lazy var calendarViewModel = CalendarViewModel()
    
    lazy var progressViewModel = ProgressViewModel(modelContext: modelContext)
    
    lazy var settingsViewModel = SettingsViewModel(modelContext: modelContext)
    
    lazy var trainingData = TrainingData(weeklySettings: WeeklySettings())
    
    lazy var trainingViewModel = TrainingViewModel()
    





  


    

    
    // ✅ NEUER INIT
      private init() {
          // 1. SwiftData ZUERST
          self.modelContainer = PersistenceController.shared.container
          self.modelContext = modelContainer.mainContext
          
          // 2. AUTH SERVICE erstellen (Mock/Real Switch)
          #if DEBUG
          self.authService = AuthService(authServiceProtocol: MockAuthService())
          #else
          self.authService = AuthService(authServiceProtocol: RealAuthService())
          #endif
          
          // 3. Services (nicht lazy - leichtgewichtig)
          self.emailParser = EmailParserService()
          self.emailService = EmailService()
          
        
      }
  }
