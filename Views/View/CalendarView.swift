

import SwiftUI
import SwiftData

struct CalendarView: View {
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var progressVM: ProgressViewModel
    
    @EnvironmentObject var appointmentViewModel: AppointmentViewModel
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    
    

    
    @State private var showFilterSheet = false
    @State private var selectedVideo: Video?
    @State private var pickerPresented = false
    
    
    @Environment(\.modelContext) var modelContext
    @State private var currentWeekOffset = 0
    
    @State private var showProfile = false
    @State private var showSettings = false
    
    
    var onVideoSelected: ((Video) -> Void)? = nil
    
    init(repository: VideoRepositoryProtocol,
         onVideoSelected: ((Video) -> Void)? = nil) {
        self.onVideoSelected = onVideoSelected
        
    }
    @State private var activeSheet: SheetType?
    @State private var selectedVideoForConfig: Video?
    @State private var playbackSettings = PlaybackSettings()


    enum SheetType: Identifiable {
        case
        library,
        profile,
        appointments,
        settings
        var id: Self { self }
    }
    
    
    
    var body: some View {

            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                
                VStack {
                    CompactWeekView()
                    
                    Divider()
                        .padding(.vertical,8)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            SelectedDateInfoView(
                                selectedDate: calendarViewModel.selectedDate,
                                appointments: appointmentViewModel.appointments.filter { Calendar.current.isDate($0.date, inSameDayAs: calendarViewModel.selectedDate) },
                                onAddAppointment: { print("Add Appointment tapped") })
                            //TODO: Funktion für onAddExercise
                            .padding(.horizontal, 16)
                            
                            ExercisesForDateView(
                                selectedDate: calendarViewModel.selectedDate,
                                onAddExercise: {
                                    activeSheet = .library  // ← EINFACH!
                                }
                            )

                            
                        }
                  //      .padding()
                    }
                }
                .navigationTitle("Kalender")
                .toolbar {
                    toolbarContent
                }
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showProfile) {
                       ProfileView()
                   }
  
                   .onChange(of: calendarViewModel.selectedDate) { _, newDate in
                       if let user = authService.currentUser {
                           progressVM.loadToday(for: user, date: newDate)  // ← NICHT calculateProgress!
                       }
                    }
                
                   .sheet(item: $activeSheet) { sheet in
                       switch sheet {
                       case .library:
                           NavigationStack {
                               LibraryView(
                                   onVideoSelected: { video in
                                       progressVM.addVideo(video, to: calendarViewModel.selectedDate, for: authService.currentUser!)
                                       activeSheet = nil
                                   }
                               )
                               .environmentObject(authService)
                               .environmentObject(videoLibraryVM)
                               .environmentObject(settingsVM)
                           }
                       case .profile:
                           ProfileView()
                       case .settings:
                           SettingsView()
                               .environmentObject(settingsVM)
                               .environment(\.modelContext, modelContext)
                       case .appointments:
                           EmptyView()
                       }
                   }

            
        }
    }
    
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        // LINKS: Plus + Filter
        ToolbarItem(placement: .topBarLeading) {
            HStack(spacing: 12) {
                
            }
        }
        
        // RECHTS: Profile-Menü
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Profil") {
                    activeSheet = .profile                 }
                Button("Einstellungen") {
                    activeSheet = .settings
                }
            } label: {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
        }
    }
}
#Preview("CalendarView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: VideoSchedule.self, Appointment.self,
        configurations: config
    )
    
    let context = ModelContext(container)
    
    let authService = AuthService(authServiceProtocol: MockAuthService())
    let progressVM = ProgressViewModel(modelContext: context)
    let appointmentVM = AppDependencies.shared.appointmentViewModel
    let calendarVM = CalendarViewModel()
    let settingsVM = SettingsViewModel(modelContext: context, authService: authService)
    
    // ← VIDEO LIBRARY VM FEHLT! Hinzufügen:
    let videoLibraryVM = VideoLibraryViewModel(
        repository: VideoRepository(modelContext: context, storageService: .shared, thumbnailService: .shared),
        modelContext: context,
        storageService: .shared
    )
    
    let previewRepo = VideoRepository(modelContext: context, storageService: .shared, thumbnailService: .shared)
    
    return CalendarView(repository: previewRepo)
        .environmentObject(authService)
        .environmentObject(progressVM)
        .environmentObject(appointmentVM)
        .environmentObject(calendarVM)
        .environmentObject(settingsVM)
        .environmentObject(videoLibraryVM)  // ← HIER!
        .modelContainer(container)
        .frame(height: 900)
}
