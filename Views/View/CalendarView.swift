//
//  CalendarView.swift
//  Agil
//
//  Created by Christiane Roth on 19.11.25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var progressVM: ProgressViewModel
    
    @EnvironmentObject var appointmentViewModel: AppointmentViewModel
    @EnvironmentObject var calendarViewModel: CalendarViewModel
 //   @EnvironmentObject var trainingViewModel: TrainingViewModel
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
                       SettingsView()  // oder settingsVM.user falls verfügbar
                           .environmentObject(settingsVM)  // falls SettingsView das braucht
                           .environment(\.modelContext, modelContext)
                   }
                   .onChange(of: calendarViewModel.selectedDate) { oldDate, newDate in
                        if let user = authService.currentUser {
                            progressVM.calculateProgress(for: user)
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

