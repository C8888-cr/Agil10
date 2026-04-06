// Core/DI/AppDependencies.swift
import Foundation
import SwiftData

@MainActor
class AppDependencies: ObservableObject {
    static let shared = AppDependencies()
    
    // MARK: - Infrastructure
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    // MARK: - Auth ALT (bleibt bis alle ViewModels migriert sind)
    let authService: AuthService  // ← wieder rein, aber nur temporär!
    
    // MARK: - Auth NEU (Clean Architecture)
    private lazy var authServiceProtocol: AuthServiceProtocol = FirebaseAuthService()
    private lazy var userRepository = UserRepository(modelContext: modelContext)
    lazy var sessionManager = SessionManager(userRepository: userRepository)
    
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(
            session: sessionManager,
            loginUseCase: LoginUseCase(authService: authServiceProtocol),
            signUpUseCase: SignUpUseCase(authService: authServiceProtocol),
            signOutUseCase: SignOutUseCase(authService: authServiceProtocol),
            resetPasswordUseCase: ResetPasswordUseCase(authService: authServiceProtocol)
        )
    }

    // MARK: - Services
    let emailParser: EmailParserService
    let emailService: EmailService
    
    // MARK: - Repositories
    lazy var appointmentRepository = AppointmentRepository(
        modelContext: modelContext,
        authService: authService
    )
    lazy var videoRepository = VideoRepository(
        modelContext: modelContext,
        storageService: .shared,
        thumbnailService: .shared
    )
    lazy var videoScheduleRepository = VideoScheduleRepository(
        modelContext: modelContext
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
    
    // MARK: - ViewModels (noch nicht migriert)
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
    lazy var videoLibraryVM = VideoLibraryViewModel(
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
        self.modelContainer = PersistenceController.shared.container
        self.modelContext = modelContainer.mainContext
        
        #if DEBUG
        self.authService = AuthService(
            authServiceProtocol: FirebaseAuthService(),
            modelContext: modelContext
        )
        #else
        self.authService = AuthService(
            authServiceProtocol: FirebaseAuthService(),
            modelContext: modelContext
        )
        #endif
        
        self.emailParser = EmailParserService()
        self.emailService = EmailService()
        
        cleanupMockData()
    }
    
    private func cleanupMockData() {
        let key = "mockDataCleaned_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        
        let mockId = UUID(uuidString: "12345678-1234-5678-1234-123456789ABC")!
        
        let scheduleDescriptor = FetchDescriptor<VideoSchedule>(
            predicate: #Predicate { $0.user?.id == mockId }
        )
        if let mockSchedules = try? modelContext.fetch(scheduleDescriptor) {
            mockSchedules.forEach { modelContext.delete($0) }
            print("🧹 \(mockSchedules.count) Mock-Schedules gelöscht")
        }
        
        let videoDescriptor = FetchDescriptor<Video>(
            predicate: #Predicate { $0.user == nil || $0.user?.id == mockId }
        )
        if let mockVideos = try? modelContext.fetch(videoDescriptor) {
            mockVideos.forEach { modelContext.delete($0) }
            print("🧹 \(mockVideos.count) Mock-Videos gelöscht")
        }
        
        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: key)
        print("🧹 Mock-Daten bereinigt (einmalig)")
    }
}
