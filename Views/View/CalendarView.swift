//
//  CalendarView.swift
//  Agil
//
//  Created by Christiane Roth on 19.11.25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @EnvironmentObject var appointmentViewModel: AppointmentViewModel
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var trainingViewModel: TrainingViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    
    
    let currentUser: User
    
    @State private var showFilterSheet = false
    @State private var selectedVideo: Video?
    @State private var pickerPresented = false
    
    
    @Environment(\.modelContext) var modelContext
    @State private var currentWeekOffset = 0
    
    @State private var showProfile = false
    @State private var showSettings = false
    
    
    var onVideoSelected: ((Video) -> Void)? = nil
    
    init(currentUser: User,
         repository: VideoRepositoryProtocol,
         onVideoSelected: ((Video) -> Void)? = nil) {
             self.currentUser = currentUser
        self.onVideoSelected = onVideoSelected
        
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
                                onAddExercise: { print("Add exercise tapped") })
                            //TODO: Funktion für onAddExercise
                            
                            
                            ExercisesForDateView(
                                selectedDate: calendarViewModel.selectedDate,
                                onAddExercise: {
                                    print("Add exercise tapped")
                                }
                            )
                            
                        }
                        .padding()
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
                   .sheet(isPresented: $showSettings) {
                       SettingsView(user: currentUser)  // oder settingsVM.user falls verfügbar
                           .environmentObject(settingsVM)  // falls SettingsView das braucht
                           .environment(\.modelContext, modelContext)
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
                    showProfile = true
                }
                Button("Einstellungen") {
                    showSettings = true
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
    let container = PreviewHelper.createModelContainer()
    let context = ModelContext(container)
    
    let testUser = User(
        id: UUID(),
        email: "test@example.com",
        passwordHash: "1234"
    )
    let settingsVM = SettingsViewModel( modelContext: context)
    
    
    CalendarView(
        currentUser: testUser,
        repository: PreviewHelper.createVideoRepository() // ✅ NEUER HELPER
    )
    .environmentObject(PreviewHelper.createAppointmentViewModel())
    .environmentObject(CalendarViewModel())
    .environmentObject(TrainingViewModel())
    .environmentObject(VideoLibraryViewModel(repository: PreviewHelper.createVideoRepository()))
    .modelContainer(container)
    .environmentObject(settingsVM)
}
