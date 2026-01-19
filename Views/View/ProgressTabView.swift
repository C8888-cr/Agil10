//
//  WeeklyProgressView.swift
//  Agil5.0
//
//  Migrated to SwiftData Architecture
//
import SwiftUI
import SwiftData


struct ProgressTabView: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var activeSheet: SheetType?


    enum SheetType: Identifiable {
        case
        profile,
        settings
        var id: Self { self }
    }

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 🎯 Wochenübersicht mit schönen Balken
                    WeeklyProgressCard()
                    
                    // 📊 Exercise Type Breakdown
                    ExerciseTypeStatsCard()
                    
                    // 📅 Tägliche Aufschlüsselung
                    DailyBreakdownCard()
                    
                    // 📈 Gesamtstatistiken
                    OverallStatisticsCard()
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Fortschritt")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Profil") { activeSheet = .profile }
                            Button("Einstellungen") { activeSheet = .settings }
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .settings:
                    SettingsView() // ← user Parameter
                        .environmentObject(settingsVM)   // ← VM injizieren!
                        .environment(\.modelContext, settingsVM.modelContext)
                        .onDisappear {
                            progressVM.loadToday(for: authService.currentUser!)
                        }
                    
                case .profile:
                    ProfileView(profileVM: profileVM) // Profil View mit dem richtigen Parameter erstellen
                              .environment(\.modelContext, settingsVM.modelContext)
                }
            }
            .onAppear {
                guard let user = authService.currentUser else { return }
                progressVM.calculateAllProgress(for: user)
            }
        }
    }
}
// MARK: - Weekly Progress Card
struct WeeklyProgressCard: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    private let weekDays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wochenübersicht")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Dein Trainingsfortschritt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Wochenfortschritt Badge
                Text("\(Int(progressVM.weeklyProgress * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accent.opacity(0.15))
                    .cornerRadius(10)
            }
            
            // Balken für jeden Wochentag
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    DayProgressBar(
                        dayName: weekDays[index],
                        progress: dailyProgress(for: index),
                        isToday: isToday(index)
                    )
                }
            }
            .frame(height: 120)
            
            // Legende
            HStack(spacing: 16) {
                LegendItem(color: .accent, text: "Erledigt")
                LegendItem(color: .gray.opacity(0.3), text: "Ausstehend")
            }
            .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func dailyProgress(for dayIndex: Int) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return 0.0
        }
        
        guard let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
            return 0.0
        }
        
        let schedules = progressVM.schedulesFor(date: targetDate)
        let completedSchedules = schedules.filter { $0.isCompleted }
        
        guard !schedules.isEmpty else { return 0.0 }
        
        // Hole Tagesziel
        guard let goal = settingsVM.preferences.getGoalFor(dayOfWeek: dayIndex) else {
            return 0.0
        }
        
        let completedMinutes = completedSchedules.reduce(0) { $0 + $1.totalDurationMinutes }
        let targetMinutes = goal.targetMinutes
        
        return targetMinutes > 0 ? min(1.0, Double(completedMinutes) / Double(targetMinutes)) : 0.0
    }
    
    private func isToday(_ index: Int) -> Bool {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: Date())
        let todayIndex = (rawWeekday - firstWeekday + 7) % 7
        return index == todayIndex
    }
}
struct DayProgressBar: View {
    let dayName: String
    let progress: Double
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            // Balken
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 80)
                
                // Progress
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: progress > 0 ? [.accent, .accent.opacity(0.7)] : [.gray.opacity(0.3)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: max(4, progress * 80))
                    .animation(.spring(response: 0.6), value: progress)
            }
            
            // Tag Label
            Text(dayName)
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .accent : .secondary)
            
            // Heute Indikator
            if isToday {
                Circle()
                    .fill(Color.accent)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}
// MARK: - Exercise Type Stats Card
struct ExerciseTypeStatsCard: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Übungsarten")
                .font(.title2)
                .fontWeight(.bold)
            
            let stats = getExerciseTypeStats()
            
            if stats.isEmpty {
                Text("Noch keine Trainingsdaten")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(stats.sorted { $0.value.minutes > $1.value.minutes }), id: \.key) { category, data in
                        ExerciseTypeStatItem(
                            category: category,
                            minutes: data.minutes,
                            isCompleted: data.isCompleted
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func getExerciseTypeStats() -> [ExerciseCategory: (minutes: Int, isCompleted: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return [:]
        }
        
        var stats: [ExerciseCategory: (minutes: Int, isCompleted: Bool)] = [:]
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            let schedules = progressVM.schedulesFor(date: date)
            
            for schedule in schedules {
                guard let video = schedule.video else { continue }
                
                let category = video.category
                let minutes = schedule.totalDurationMinutes
                let isCompleted = schedule.isCompleted
                
                if var existing = stats[category] {
                    existing.minutes += minutes
                    existing.isCompleted = existing.isCompleted && isCompleted
                    stats[category] = existing
                } else {
                    stats[category] = (minutes: minutes, isCompleted: isCompleted)
                }
            }
        }
        
        return stats
    }
}
struct ExerciseTypeStatItem: View {
    let category: ExerciseCategory
    let minutes: Int
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // Icon mit Gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [category.color, category.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                // Checkmark wenn erledigt
                if isCompleted {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 18, height: 18)
                                )
                        }
                        Spacer()
                    }
                    .frame(width: 50, height: 50)
                }
            }
            
            // Category Name
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            // Dauer
            Text("\(minutes) Min")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(category.color.opacity(0.1))
        .cornerRadius(12)
    }
}
// MARK: - Daily Breakdown Card
struct DailyBreakdownCard: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    private let weekDays = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tagesübersicht")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(0..<7, id: \.self) { index in
                DailyBreakdownRow(
                    dayName: weekDays[index],
                    shortName: String(weekDays[index].prefix(2)),
                    progress: dailyProgress(for: index),
                    watchedMinutes: watchedMinutes(for: index),
                    targetMinutes: targetMinutes(for: index),
                    isToday: isToday(index)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func dailyProgress(for dayIndex: Int) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return 0.0
        }
        
        guard let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
            return 0.0
        }
        
        let schedules = progressVM.schedulesFor(date: targetDate)
        let completedSchedules = schedules.filter { $0.isCompleted }
        
        guard let goal = settingsVM.preferences.getGoalFor(dayOfWeek: dayIndex) else {
            return 0.0
        }
        
        let completedMinutes = completedSchedules.reduce(0) { $0 + $1.totalDurationMinutes }
        let targetMinutes = goal.targetMinutes
        
        return targetMinutes > 0 ? min(1.0, Double(completedMinutes) / Double(targetMinutes)) : 0.0
    }
    
    private func watchedMinutes(for dayIndex: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return 0
        }
        
        guard let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
            return 0
        }
        
        let schedules = progressVM.schedulesFor(date: targetDate)
        let completedSchedules = schedules.filter { $0.isCompleted }
        
        return completedSchedules.reduce(0) { $0 + $1.totalDurationMinutes }
    }
    
    private func targetMinutes(for dayIndex: Int) -> Int {
        return settingsVM.preferences.getGoalFor(dayOfWeek: dayIndex)?.targetMinutes ?? 0
    }
    
    private func isToday(_ index: Int) -> Bool {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let rawWeekday = calendar.component(.weekday, from: Date())
        let todayIndex = (rawWeekday - firstWeekday + 7) % 7
        return index == todayIndex
    }
}
struct DailyBreakdownRow: View {
    let dayName: String
    let shortName: String
    let progress: Double
    let watchedMinutes: Int
    let targetMinutes: Int
    let isToday: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Day Circle
            ZStack {
                Circle()
                    .fill(isToday ? Color.accent.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(shortName)
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundColor(isToday ? .accent : .secondary)
            }
            
            // Day Name
            Text(dayName)
                .font(.subheadline)
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundColor(isToday ? .primary : .secondary)
                .frame(width: 100, alignment: .leading)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.accent, .accent.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            
            // Minutes
            Text("\(watchedMinutes)/\(targetMinutes)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(progress >= 1.0 ? .green : .secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}
// MARK: - Overall Statistics Card
struct OverallStatisticsCard: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gesamtstatistiken")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticItem(
                    icon: "play.circle.fill",
                    value: "\(progressVM.lifetimeCompletedWorkouts)",
                    label: "Videos geschaut",
                    color: Color.accent
                )
                
                StatisticItem(
                    icon: "clock.fill",
                    value: "\(progressVM.lifetimeCompletedMinutes)",
                    label: "Minuten trainiert",
                    color: Color.blue
                )
                
                StatisticItem(
                    icon: "flame.fill",
                    value: "\(progressVM.lifetimeStreak)",
                    label: "Tage Streak",
                    color: Color.orange
                )
                
                StatisticItem(
                    icon: "star.fill",
                    value: String(format: "%.1f", averageRating()),
                    label: "Ø Bewertung",
                    color: Color.yellow
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func averageRating() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return 0.0
        }
        
        var allRatings: [Int] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            let schedules = progressVM.schedulesFor(date: date)
            // ✅ BESTE VARIANTE:
            let completedSchedules = schedules.filter {
                       $0.isCompleted && ($0.rating ?? 0) > 0
                   }
                   allRatings.append(contentsOf: completedSchedules.compactMap { $0.rating })
        }
        
        guard !allRatings.isEmpty else { return 0.0 }
        
        let sum = allRatings.reduce(0, +)
        return Double(sum) / Double(allRatings.count)
    }
}
struct StatisticItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            // Value
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
    }
}
