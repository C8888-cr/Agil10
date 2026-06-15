// Core/DI/AppDependencies.swift
import Foundation
import SwiftData

@MainActor
class AppDependencies: ObservableObject {
    static let shared = AppDependencies()
    
    // MARK: - Infrastructure
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    
    
    // MARK: - Auth
    private lazy var authServiceProtocol: AuthServiceProtocol = LocalAuthService()
    private lazy var userRepository = UserRepository(modelContext: modelContext)
    
    // MARK: - Biometrie-Infrastruktur
    private lazy var biometricAuthenticator: BiometricAuthenticator = LocalAuthBiometricAuthenticator()
    private lazy var biometricPreferences: BiometricPreferences = UserDefaultsBiometricPreferences()
    private lazy var biometricCredentialStorage: BiometricCredentialStorage = KeychainBiometricCredentialStorage()
    
    
    lazy var sessionManager = SessionManager(
           authService: authServiceProtocol,
           userRepository: userRepository,
        unlockUseCase: unlockAppUseCase,
        preferences: biometricPreferences
    )
    
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(
            session: sessionManager,
            loginUseCase: LoginUseCase(authService: authServiceProtocol),
            signUpUseCase: SignUpUseCase(authService: authServiceProtocol),
            signOutUseCase: SignOutUseCase(authService: authServiceProtocol),
            resetPasswordUseCase: ResetPasswordUseCase(authService: authServiceProtocol),
            deleteAccountUseCase: deleteAccountUseCase,
            resetUserDataUseCase: resetUserDataUseCase,
            loginWithBiometricUseCase: loginWithBiometricUseCase,
            credentialStorage: biometricCredentialStorage
        )
    }
    
    func makeBiometricLockViewModel() -> BiometricLockViewModel {
        BiometricLockViewModel(session: sessionManager)
    }

    // MARK: - Services
    lazy var emailParser: EmailParserService = EmailParserService(session: sessionManager)
    let emailService: EmailService
    // MARK: - Calendar Sync
    lazy var calendarSync: CalendarSyncService = EventKitCalendarSync()
    // MARK: - ics Services
    lazy var icsParser: ICSParserService = ICSParserService(session: sessionManager)
    lazy var icsImportCoordinator = ICSImportCoordinator()
    
    // MARK: - Repositories
    lazy var appointmentRepository = AppointmentRepository(
        modelContext: modelContext,
        session: sessionManager
    )
    lazy var videoRepository = VideoRepository(
        modelContext: modelContext,
        storageService: .shared,
        thumbnailService: .shared
    )
    lazy var videoScheduleRepository = VideoScheduleRepository(
        modelContext: modelContext
    )
    
    lazy var workoutLogRepository = WorkoutLogRepository(
        modelContext: modelContext
    )
    
    // MARK: - AppointmentUseCases
    lazy var addAppointmentUseCase = AddAppointmentUseCase(
        repository: appointmentRepository,
        session: sessionManager,
        calendarSync: calendarSync
    )
    lazy var deleteAppointmentUseCase = DeleteAppointmentUseCase(
        repository: appointmentRepository
    )
    lazy var cancelAppointmentUseCase = CancelAppointmentUseCase(
            repository: appointmentRepository,
            emailService: emailService,
            calendarSync: calendarSync
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
            detectChangesUseCase: detectAppointmentChangesUseCase,
            session: sessionManager,
            addAppointmentUseCase: addAppointmentUseCase,
            updateAppointmentUseCase: updateAppointmentUseCase
        )
   
    lazy var parseAppointmentsFromICSUseCase = ParseAppointmentsFromICSUseCase(
        repository: appointmentRepository,
        icsParser: icsParser,
        detectChangesUseCase: detectAppointmentChangesUseCase,
        session: sessionManager,
        addAppointmentUseCase: addAppointmentUseCase,
        updateAppointmentUseCase: updateAppointmentUseCase
    )
    lazy var updateAppointmentUseCase = UpdateAppointmentUseCase(
        repository: appointmentRepository,
        calendarSync: calendarSync
    )
    
    
    // MARK: - ScheduleUseCases
    lazy var getSchedulesForDateUseCase = GetSchedulesForDateUseCase(
        repository: videoScheduleRepository
    )
    lazy var addScheduleUseCase = AddScheduleUseCase(
        repository: videoScheduleRepository
    )
    lazy var removeScheduleUseCase = RemoveScheduleUseCase(
        repository: videoScheduleRepository
    )
    lazy var writeWorkoutLogUseCase = WriteWorkoutLogUseCase(
        repository: workoutLogRepository
    )
    lazy var toggleScheduleCompletionUseCase = ToggleScheduleCompletionUseCase(
        repository: videoScheduleRepository,
        writeWorkoutLogUseCase: writeWorkoutLogUseCase
    )
    lazy var reorderSchedulesUseCase = ReorderSchedulesUseCase(
        repository: videoScheduleRepository
    )
    
    // MARK: - HistoryUseCases
    lazy var fetchWorkoutLogsUseCase = FetchWorkoutLogsUseCase(
        repository: workoutLogRepository
    )
    
    // MARK: - VideoUseCases
    lazy var addVideoToPlanUseCase = AddVideoToPlanUseCase(
        repository: videoScheduleRepository
    )
    
    // MARK: - ProgressUseCases
    lazy var calculateDailyProgressUseCase = CalculateDailyProgressUseCase(
        repository: videoScheduleRepository
    )
    lazy var calculateWeeklyProgressUseCase = CalculateWeeklyProgressUseCase(
        repository: videoScheduleRepository
    )
    lazy var calculateLifetimeProgressUseCase = CalculateLifetimeProgressUseCase(
        repository: videoScheduleRepository
    )
    
    // MARK: - AccountUseCases
    lazy var resetUserDataUseCase = ResetUserDataUseCase(
        scheduleRepository: videoScheduleRepository,
        userRepository: userRepository,
        workoutLogRepository: workoutLogRepository
    )
    lazy var deleteAccountUseCase = DeleteAccountUseCase(
        authService: authServiceProtocol,
        scheduleRepository: videoScheduleRepository,
        userRepository: userRepository,
        session: sessionManager,
        workoutLogRepository: workoutLogRepository
    )
    
    
    
    
    // MARK: - BiometricUseCases
    lazy var unlockAppUseCase = UnlockAppUseCase(
        authenticator: biometricAuthenticator,
        preferences: biometricPreferences
    )
    lazy var enableBiometricLoginUseCase = EnableBiometricLoginUseCase(
        authenticator: biometricAuthenticator,
        preferences: biometricPreferences
    )
    lazy var disableBiometricLoginUseCase = DisableBiometricLoginUseCase(
        preferences: biometricPreferences
    )
    
    lazy var loginWithBiometricUseCase = LoginWithBiometricUseCase(
        credentialStorage: biometricCredentialStorage,
        authService: authServiceProtocol
    )
    
    
    lazy var workoutHistoryViewModel = WorkoutHistoryViewModel(
        session: sessionManager,
        fetchUseCase: fetchWorkoutLogsUseCase,
        videoRepository: videoRepository
    )
    
    // MARK: - ViewModels
    lazy var progressViewModel = ProgressViewModel(
        session: sessionManager,
        getSchedulesUseCase: getSchedulesForDateUseCase,
        addVideoToPlanUseCase: addVideoToPlanUseCase, 
        addScheduleUseCase: addScheduleUseCase,
       
        removeScheduleUseCase: removeScheduleUseCase,
        toggleCompletionUseCase: toggleScheduleCompletionUseCase,
        reorderSchedulesUseCase: reorderSchedulesUseCase,
        dailyProgressUseCase: calculateDailyProgressUseCase,
        weeklyProgressUseCase: calculateWeeklyProgressUseCase,
        lifetimeProgressUseCase: calculateLifetimeProgressUseCase
    )
    lazy var appointmentViewModel = AppointmentViewModel(
        modelContext: modelContext,
        session: sessionManager,
        repository: appointmentRepository,
        emailParser: emailParser,
        detectAppointmentChangesUseCase: detectAppointmentChangesUseCase,
        cancelAppointmentUseCase: cancelAppointmentUseCase,
        addAppointmentUseCase: addAppointmentUseCase,
        updateAppointmentUseCase: updateAppointmentUseCase,
        emailService: emailService,
        markAsNotifiedUseCase: markAsNotifiedUseCase,
        loadAppointmentsUseCase: loadAppointmentsUseCase,
        deleteAppointmentUseCase: deleteAppointmentUseCase,
        parseAppointmentsFromEmailUseCase: parseAppointmentsFromEmailUseCase,
        parseAppointmentsFromICSUseCase: parseAppointmentsFromICSUseCase,
        calendarSync: calendarSync
    )
    
    // MARK: - Calendar ViewModels (Factory)
    func makeAppointmentPlannerViewModel() -> AppointmentPlannerViewModel {
        AppointmentPlannerViewModel(calendarSync: calendarSync)
    }
    
    
    lazy var calendarViewModel = CalendarViewModel(
        session: sessionManager,
        getSchedulesUseCase: getSchedulesForDateUseCase
    )
    lazy var videoLibraryVM = VideoLibraryViewModel(
        repository: videoRepository,
        modelContext: modelContext,
        session: sessionManager
    )
    lazy var settingsViewModel = SettingsViewModel(
        modelContext: modelContext,
        session: sessionManager,
        addScheduleUseCase: addScheduleUseCase,
        removeScheduleUseCase: removeScheduleUseCase
    )
    lazy var profileViewModel = ProfileViewModel(
        userRepository: userRepository,
        session: sessionManager
    )
    
    
    
    
    // MARK: - Init
    private init() {
        self.modelContainer = PersistenceController.shared.container
        self.modelContext = modelContainer.mainContext
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
