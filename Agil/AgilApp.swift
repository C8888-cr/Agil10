import SwiftUI
import SwiftData


/*

@main
struct AgilApp: App {
    let container: ModelContainer
    let modelContext: ModelContext
    
    
    @StateObject private var appState: AppState
    @StateObject private var dataManager: DataManager
    @StateObject private var calVM: CalendarViewModel
    @StateObject private var apptVM: AppointmentViewModel
    @StateObject private var trainingVM: TrainingViewModel
    @StateObject private var settingsVM: SettingsViewModel
    @StateObject private var progressVM: ProgressViewModel
    @StateObject private var trainingData: TrainingData
 
    
    init() {
        // ModelContainer + ModelContext
        let container = PreviewHelper.createModelContainer()
        self.container = container
        let modelContext = ModelContext(container)
        self.modelContext = modelContext
        // Erzeuge Hilfs-Objekte / Dummy-User
        let dummyUser = User(email: "demo@example.com", passwordHash: "Hamlet")
        let calendarVM = CalendarViewModel()
        let appointmentVM = PreviewHelper.createAppointmentViewModel()
        let trainingViewModel = TrainingViewModel()
        let settingsViewModel = SettingsViewModel(user: dummyUser, modelContext: modelContext)
        let progressViewModel = ProgressViewModel(modelContext: modelContext)
        // AppState & DataManager
        let appState = AppState(modelContext: modelContext)
        let dataManager = DataManager(modelContext: modelContext)
        // StateObjects setzen
        // ← HINZUFÜGEN:
        let weeklySettings = WeeklySettings()
        let trainingData = TrainingData(weeklySettings: weeklySettings)
        
        
        self._calVM = StateObject(wrappedValue: calendarVM)
        self._apptVM = StateObject(wrappedValue: appointmentVM)
        self._trainingVM = StateObject(wrappedValue: trainingViewModel)
        self._settingsVM = StateObject(wrappedValue: settingsViewModel)
        self._progressVM = StateObject(wrappedValue: progressViewModel)
        self._appState = StateObject(wrappedValue: appState)
        self._dataManager = StateObject(wrappedValue: dataManager)
        // ← HINZUFÜGEN:
              self._trainingData = StateObject(wrappedValue: trainingData)
         
        
    }
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Optional: LoadingView, hier einfach direkt Content zeigen
                if let _ = appState.currentUser {
                    ContentView()
                        .environmentObject(appState)
                        .environmentObject(dataManager)
                        .environmentObject(calVM)
                        .environmentObject(apptVM)
                        .environmentObject(settingsVM)
                        .environmentObject(trainingVM)
                        .environmentObject(progressVM)
                    // ← HINZUFÜGEN:
                        .environmentObject(trainingData)
                        .modelContainer(container)
                        .environment(\.modelContext, modelContext)
                } else {
                    LoginView(loggedInUser: .constant(nil), authService: MockAuthService())
                        .environmentObject(appState)
                        .environmentObject(dataManager)
                }
            }
        }
    }
}
*/


@main
struct AgilApp: App {
    let container: ModelContainer
    let modelContext: ModelContext
    
    
    @StateObject private var appState: AppState
    @StateObject private var dataManager: DataManager
    @StateObject private var calVM: CalendarViewModel
    @StateObject private var apptVM: AppointmentViewModel
    @StateObject private var trainingVM: TrainingViewModel
    @StateObject private var settingsVM: SettingsViewModel
    @StateObject private var progressVM: ProgressViewModel
    @StateObject private var trainingData: TrainingData
    @StateObject private var videoLibraryVM: VideoLibraryViewModel
 
    
    init() {
        // ModelContainer + ModelContext
        let container = PreviewHelper.createModelContainer()
        self.container = container
        let modelContext = ModelContext(container)
        self.modelContext = modelContext
        // Erzeuge Hilfs-Objekte / Dummy-User
        let dummyUser = User(email: "demo@example.com", passwordHash: "Hamlet")
        let calendarVM = CalendarViewModel()
        let appointmentVM = PreviewHelper.createAppointmentViewModel()
        let trainingViewModel = TrainingViewModel()
        let settingsViewModel = SettingsViewModel(user: dummyUser, modelContext: modelContext)
        let progressViewModel = ProgressViewModel(modelContext: modelContext)
        // AppState & DataManager
        let appState = AppState(modelContext: modelContext)
        let dataManager = DataManager(modelContext: modelContext)
        // StateObjects setzen
        // ← HINZUFÜGEN:
        let weeklySettings = WeeklySettings()
        let trainingData = TrainingData(weeklySettings: weeklySettings)
        let videoLibraryViewModel = VideoLibraryViewModel(
            repository: VideoRepository(modelContext: modelContext)
        )
        
        
        self._calVM = StateObject(wrappedValue: calendarVM)
        self._apptVM = StateObject(wrappedValue: appointmentVM)
        self._trainingVM = StateObject(wrappedValue: trainingViewModel)
        self._settingsVM = StateObject(wrappedValue: settingsViewModel)
        self._progressVM = StateObject(wrappedValue: progressViewModel)
        self._appState = StateObject(wrappedValue: appState)
        self._dataManager = StateObject(wrappedValue: dataManager)
        // ← HINZUFÜGEN:
              self._trainingData = StateObject(wrappedValue: trainingData)
        self._videoLibraryVM = StateObject(wrappedValue: videoLibraryViewModel)
         
        
    }
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Optional: LoadingView, hier einfach direkt Content zeigen
                if let _ = appState.currentUser {
                    ContentView()
                        .environmentObject(appState)
                        .environmentObject(dataManager)
                        .environmentObject(calVM)
                        .environmentObject(apptVM)
                        .environmentObject(settingsVM)
                        .environmentObject(trainingVM)
                        .environmentObject(progressVM)
                    // ← HINZUFÜGEN:
                        .environmentObject(trainingData)
                        .environmentObject(videoLibraryVM) 
                        .modelContainer(container)
                   //     .environment(\.modelContext, modelContext)
                } else {
                    LoginView(loggedInUser: .constant(nil), authService: MockAuthService())
                        .environmentObject(appState)
                        .environmentObject(dataManager)
                }
            }
        }
    }
}

