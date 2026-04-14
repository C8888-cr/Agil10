//
//  CalendarMonthView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//


import SwiftUI
import SwiftData

struct CalendarMonthView: View {
    @Namespace private var namespace
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel
    
    @Query(sort: \Appointment.date) private var allAppointments: [Appointment]
    
    @State private var navigateToDay = false
    @State private var scrollToToday = false
    
  
    @State private var showDailyPlan = false
    @State private var showWeeklyPlan = false
    @State private var showSettingsView = false
    @State private var showProfile = false
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekDays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    
    private func hasAppointments(on date: Date) -> Bool {
        allAppointments.contains {
            Calendar.current.isDate($0.date, inSameDayAs: date) &&
            $0.status != .cancelled
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Text(calendarViewModel.monthTitle(for: calendarViewModel.currentMonth))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Recurrence Buttons
                    HStack(spacing: 8) {
                        recurrenceButton(.single, label: "1×")
                        recurrenceButton(.weekly, label: "W")
                        recurrenceButton(.daily, label: "D")
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // MARK: - Wochentage Header
                HStack {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                    .padding(.top, 4)
                
                // MARK: - Monats-Scroll
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(-6...6, id: \.self) { offset in
                                let month = Calendar.current.date(
                                    byAdding: .month,
                                    value: offset,
                                    to: Calendar.current.startOfDay(for: Date())
                                        .firstDayOfMonth()
                                ) ?? Date()
                                
                                MonthGridView(
                                    month: month,
                                    selectedDate: calendarViewModel.selectedDate,
                                    hasSchedules: calendarViewModel.hasSchedules,
                                    hasAppointments: hasAppointments,
                                    onSelectDate: { date in
                                        calendarViewModel.select(date: date)
                                        navigateToDay = true
                                    }
                                )
                                .id(offset)
                            }
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(0, anchor: .top)
                    }
                    .onChange(of: scrollToToday) { _, newValue in
                        if newValue {
                            withAnimation {
                                proxy.scrollTo(0, anchor: .top)
                            }
                            scrollToToday = false
                        }
                    }
                }
                
                // MARK: - Heute Button
                HStack {
                    Button {
                        calendarViewModel.goToToday()
                        scrollToToday = true
                    } label: {
                        Label("Heute", systemImage: "calendar.circle.fill")
                               .font(.subheadline)
                               .fontWeight(.semibold)
                               .padding(.horizontal, 14)
                               .padding(.vertical, 8)
                               .glassEffect(in: Capsule())
                       }
                    .buttonStyle(.borderless)
                    .padding()
                    
                    Spacer()
                }
            }
            
            .navigationDestination(isPresented: $navigateToDay) {
                CalendarDayView()
                    .environmentObject(calendarViewModel)
                    .environmentObject(settingsVM)
                    .environmentObject(session)
                    .environmentObject(progressVM)  // ← NEU
                    .environmentObject(videoLibraryVM)  // ← auch das
            }
            .navigationDestination(isPresented: $showSettingsView) {
                SettingsView()
                    .environmentObject(settingsVM)
                    .environmentObject(session)
                    .environmentObject(videoLibraryVM)
                    .environmentObject(progressVM)
            }
            
            
            
          
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Profil") { showProfile = true }
                  
                    } label: {
                        if let user = session.currentUser,
                           let imageData = user.profileImage,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.accentColor.opacity(0.3))
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Text(session.currentUser?.initials ?? "?")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.accentColor)
                                )
                        }
                    }
                }
            }
            // Sheets ergänzen
            .sheet(isPresented: $showProfile) {
                ProfileView()
                  
                
            }

            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 8) {

                    // Tagesplan — nur bei D
                    if settingsVM.preferences.activePlanMode == .daily {
                        Button { showDailyPlan = true } label: {
                            Label("Tagesplan", systemImage: "sun.max.fill")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .glassEffect(in: Capsule())
                        }
                        .buttonStyle(.borderless)
                    }

                    // Wochenplan — nur bei W
                    if settingsVM.preferences.activePlanMode == .weekly {
                        Button { showWeeklyPlan = true } label: {
                            Label("Wochenplan", systemImage: "calendar.badge.plus")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .glassEffect(in: Capsule())
                        }
                        .buttonStyle(.borderless)
                    }

                    // Einstellungen — immer rechts
                    Button { showSettingsView = true } label: {
                        Label("Einstellungen", systemImage: "target")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .glassEffect(in: Capsule())
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.bottom, 16)
                .padding(.trailing, 16)
            }
            .sheet(isPresented: $showDailyPlan) {
                WeekPlannerSheet(
                    rule: .daily,
                    onSave: { startDate, plan, strategy in
                        guard let user = session.currentUser else { return }
                        settingsVM.applyWeekPlan(
                            startDate: startDate,
                            weekPlan: plan,
                            rule: .daily,
                            strategy: strategy,
                            user: user
                        )
                        showDailyPlan = false
                    },
                    onCancel: { showDailyPlan = false }
                )
                .environmentObject(settingsVM)
                .environmentObject(videoLibraryVM)
                .environmentObject(session)
            }
            .sheet(isPresented: $showWeeklyPlan) {
                WeekPlannerSheet(
                    rule: .weekly,
                    onSave: { startDate, plan, strategy in
                        guard let user = session.currentUser else { return }
                        settingsVM.applyWeekPlan(
                            startDate: startDate,
                            weekPlan: plan,
                            rule: .weekly,
                            strategy: strategy,
                            user: user
                        )
                        showWeeklyPlan = false
                    },
                    onCancel: { showWeeklyPlan = false }
                )
                .environmentObject(settingsVM)
                .environmentObject(videoLibraryVM)
                .environmentObject(session)
            }
        }
    }
    
    @ViewBuilder
    private func recurrenceButton(_ rule: RecurrenceRule, label: String) -> some View {
        let isActive = settingsVM.preferences.activePlanMode == rule
        
        
        Button {
            settingsVM.setActiveMode(rule)
            if let user = session.currentUser {
                // ✅ selectedDate statt Date():
                       progressVM.loadToday(for: user, date: calendarViewModel.selectedDate)
                   }
        } label: {
            Text(label)
                       .font(.caption)
                       .fontWeight(.semibold)
                       .foregroundColor(isActive ? .primary : .secondary)
                       .padding(.horizontal, 12)
                       .padding(.vertical, 6)
                       .glassEffect(in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isActive ? Color.accent : Color.clear, lineWidth: 1.5)
                                  )
            
                      
               }
               .buttonStyle(.borderless)
    }
}
