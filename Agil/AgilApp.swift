import SwiftUI
import SwiftData



@main
struct AgilApp: App {

    let dependencies = AppDependencies.shared
    
    
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
        
        
        let calendarVM = CalendarViewModel()
        let appointmentVM = PreviewHelper.createAppointmentViewModel()
        let trainingViewModel = TrainingViewModel()
        let settingsViewModel = SettingsViewModel(modelContext: dependencies.modelContext)  // ← KEIN User!
        let progressViewModel = ProgressViewModel(modelContext: dependencies.modelContext)

        let appState = AppState(modelContext: dependencies.modelContext)
        let dataManager = DataManager(modelContext: dependencies.modelContext)
                                                  
                                                  
        let weeklySettings = WeeklySettings()
        let trainingData = TrainingData(weeklySettings: weeklySettings)
        let videoLibraryViewModel = VideoLibraryViewModel(
            repository: VideoRepository(modelContext: dependencies.modelContext)
        )
        
        // StateObjects
        self._calVM = StateObject(wrappedValue: calendarVM)
        self._apptVM = StateObject(wrappedValue: appointmentVM)
        self._trainingVM = StateObject(wrappedValue: trainingViewModel)
        self._settingsVM = StateObject(wrappedValue: settingsViewModel)
        self._progressVM = StateObject(wrappedValue: progressViewModel)
        self._appState = StateObject(wrappedValue: appState)
        self._dataManager = StateObject(wrappedValue: dataManager)
        self._trainingData = StateObject(wrappedValue: trainingData)
        self._videoLibraryVM = StateObject(wrappedValue: videoLibraryViewModel)
         
        
    }
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Optional: LoadingView, hier einfach direkt Content zeigen
                if let _ = appState.currentUser {
                    ContentView()
                  
                        .environmentObject(dependencies.appointmentViewModel)
                        .environmentObject(appState)
                        .environmentObject(dataManager)
                        .environmentObject(calVM)
                        .environmentObject(apptVM)
                        .environmentObject(settingsVM)
                        .environmentObject(trainingVM)
                        .environmentObject(progressVM)
           
                        .environmentObject(trainingData)
                        .environmentObject(videoLibraryVM) 
                        .modelContainer(dependencies.modelContainer)
                } else {
                    LoginView(loggedInUser: .constant(nil), authService: MockAuthService())
                        .environmentObject(appState)
                        .environmentObject(dataManager)
                        .modelContainer(dependencies.modelContainer)
                }
            }
        }
    }
}

