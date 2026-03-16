//
//  WeekPlannerSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.03.26.
//


import SwiftUI
import SwiftData

struct WeekPlannerSheet: View {
    
    // Neue State-Variablen oben ergänzen:
    @State private var mergeStrategy: MergeStrategy = .replaceAll
    @State private var showMergeDialog = false
    @State private var existingScheduleCount = 0
    @State private var weekPlannerRuleToShow: RecurrenceRule? = nil
    
    let rule: RecurrenceRule // .daily oder .weekly
    let onSave: (Date, [Int: [PlannedVideo]], MergeStrategy) -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel
    @EnvironmentObject var authService: AuthService
    
    @State private var startDate: Date = Date()
    @State private var selectedDayIndex: Int = 0
    @State private var showStartDatePicker = false
    @State private var showLibrary = false
    @State private var selectedVideoForConfig: Video?
    @State private var showWarning = false
    
    // Temporäre Video-Planung pro Tag (dayIndex → Videos mit Config)
    @State private var weekPlan: [Int: [PlannedVideo]] = {
        var plan: [Int: [PlannedVideo]] = [:]
        for i in 0..<7 { plan[i] = [] }
        return plan
    }()
    
    struct PlannedVideo: Identifiable {
        let id = UUID()
        let video: Video
        var repetitions: Int
        var loopDurationSeconds: Int
        var pauseSeconds: Int
    }
    
    // Aktive Trainingstage
    private var activeDayIndices: [Int] {
        settingsVM.preferences.weeklyGoals
            .filter { $0.isActive && $0.targetMinutes > 0 }
            .map { $0.dayOfWeek }
            .sorted()
    }
    
    // MARK: - Alle Tage (nicht nur aktive)
    private var activeDays: [WeekDay] {
        WeekDay.allCases  // ✅ alle 7 Tage
    }

    // Geplante Minuten für einen Tag berechnen
    private func plannedMinutes(for dayIndex: Int) -> Int {
        let videos = rule == .daily ? (weekPlan[0] ?? []) : (weekPlan[dayIndex] ?? [])
        return videos.reduce(0) { total, planned in
            let reps = planned.repetitions
            let loop = planned.loopDurationSeconds
            let pause = planned.pauseSeconds
            let seconds = (loop * reps) + (pause * max(0, reps - 1))
            return total + (seconds / 60)
        }
    }

    // Zielminuten für einen Tag
    private func targetMinutes(for dayIndex: Int) -> Int {
        settingsVM.preferences.weeklyGoals
            .first { $0.dayOfWeek == dayIndex }?.targetMinutes ?? 0
    }

    private func isActiveDay(_ dayIndex: Int) -> Bool {
        targetMinutes(for: dayIndex) > 0
    }
    
    // Ob der aktuelle Tag Videos hat
    private func hasVideos(for dayIndex: Int) -> Bool {
        !(weekPlan[dayIndex]?.isEmpty ?? true)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                startDateSection
                warningBanner
                
                if rule == .daily {
                    dailyVideoList
                } else {
                    dayTabBar
                    Divider()
                    dayVideoList
                }
                Spacer()
                saveButton
            }
            .navigationTitle(rule == .daily ? "Täglicher Plan" : "Wöchentlicher Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { onCancel() }
                }
            }
            .sheet(isPresented: $showLibrary) {
                NavigationStack {
                    LibraryView(
                        onVideoSelected: { video in
                            guard selectedVideoForConfig == nil else { return }
                            showLibrary = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                selectedVideoForConfig = video
                            }
                        }
                    )
                    .environmentObject(authService)
                    .environmentObject(videoLibraryVM)
                    .environmentObject(settingsVM)
                }
            }
            .sheet(item: $selectedVideoForConfig) { video in
                VideoQuickConfigSheet(
                    video: video,
                    onAdd: { reps, loopDuration, pause in
                        let planned = PlannedVideo(
                            video: video,
                            repetitions: reps,
                            loopDurationSeconds: loopDuration,
                            pauseSeconds: pause
                        )
                        if rule == .daily {
                            guard !(weekPlan[0]?.contains { $0.video.id == video.id } ?? false) else {
                                print("⚠️ Duplikat verhindert")
                                selectedVideoForConfig = nil
                                return
                            }
                            weekPlan[0, default: []].append(planned)
                        } else {
                            guard !(weekPlan[selectedDayIndex]?.contains { $0.video.id == video.id } ?? false) else {
                                print("⚠️ Duplikat verhindert")
                                selectedVideoForConfig = nil
                                return
                            }
                            weekPlan[selectedDayIndex, default: []].append(planned)
                        }
                        selectedVideoForConfig = nil
                    },
                    onCancel: {
                        selectedVideoForConfig = nil
                    }
                )
            }
            // ✅ confirmationDialog auf NavigationStack-Ebene
            .confirmationDialog(
                "Bestehende Videos gefunden",
                isPresented: $showMergeDialog,
                titleVisibility: .visible
            ) {
                Button("Alles ersetzen", role: .destructive) {
                    mergeStrategy = .replaceAll
                }
                Button("Plan hinzufügen") {
                    mergeStrategy = .addToPlan
                }
                Button("Abbrechen", role: .cancel) {
                    startDate = Date()
                }
            } message: {
                Text("Ab dem \(startDate, format: .dateTime.day().month()) hast du bereits \(existingScheduleCount) Videos geplant. Was soll damit passieren?")
            }
        }
    }
    private var dailyVideoList: some View {
        ScrollView {
            VStack(spacing: 12) {
                
                // Info
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Diese Videos werden täglich wiederholt")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("An allen aktiven Trainingstagen (\(activeDays.map { $0.shortName }.joined(separator: ", ")))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.accent.opacity(0.08))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Video Liste
                let videos = weekPlan[0] ?? []
                
                if videos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "video.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Noch keine Videos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(videos) { planned in
                        plannedVideoRow(planned, dayIndex: 0)
                    }
                }
                
            
                
                // + Hinzufügen
                Button {
                    showLibrary = true
                } label: {
                    Label("Video hinzufügen", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                minutesSummary
            }
    
            
            
            .padding(.vertical, 16)
        }
    }
    
    private var minutesSummary: some View {
        Group {
            if rule == .weekly {
                let planned = plannedMinutes(for: selectedDayIndex)
                let target = targetMinutes(for: selectedDayIndex)
                let remaining = target - planned
                let isOver = planned > target
                
                if target > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "")
                            .font(.caption)
                            .foregroundColor(isOver ? .red : .secondary)
                        
                        Text(isOver
                             ? "\(planned) Min geplant · \(planned - target) Min über Ziel"
                             : "\(planned) Min geplant · \(remaining) Min verbleibend"
                        )
                        .font(.caption)
                        .foregroundColor(isOver ? .red : .secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
            } else {
                // Daily — einfacher Zähler
                let totalPlanned = weekPlan[0]?.reduce(0) { total, p in
                    let seconds = (p.loopDurationSeconds * p.repetitions) +
                        (p.pauseSeconds * max(0, p.repetitions - 1))
                    return total + (seconds / 60)
                } ?? 0
                
                if totalPlanned > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(totalPlanned) Min geplant")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    // MARK: - Start Datum Section
    private var startDateSection: some View {
        VStack(spacing: 0) {
            Button {
                showStartDatePicker.toggle()
            } label: {
                HStack {
                    Label("Startdatum", systemImage: "calendar")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(startDate, format: .dateTime.day().month().year())
                        .foregroundColor(.accent)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showStartDatePicker ? 90 : 0))
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .buttonStyle(.plain)
            
            if showStartDatePicker {
                DatePicker(
                    "",
                    selection: $startDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .tint(.accent)
                .onChange(of: startDate) { _, newDate in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showStartDatePicker = false
                    }
                    checkExistingSchedules(from: newDate)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showStartDatePicker)
    }
    
    // MARK: - Warning Banner
    private var warningBanner: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMM"
        let dateString = formatter.string(from: startDate)
        
        let text: String
        let color: Color
        let icon: String
        
        switch mergeStrategy {
        case .replaceAll:
            text = "Alle bestehenden Videos ab \(dateString) werden ersetzt."
            color = .orange
            icon = "exclamationmark.triangle.fill"
        case .addToPlan:
            text = "Der Plan wird zu bestehenden Videos hinzugefügt."
            color = .blue
            icon = "plus.circle.fill"
        }
        
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mergeStrategy == .replaceAll ? "Alles ersetzen" : "Plan hinzufügen")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(text)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // ✅ Strategie ändern Button
            Button {
                showMergeDialog = true
            } label: {
                Text("Ändern")
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(width: 4)
                .foregroundColor(color),
            alignment: .leading
        )
    }
    
    // MARK: - Day Tab Bar
    private var dayTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(activeDays, id: \.self) { day in
                    dayTab(day)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    private func checkExistingSchedules(from date: Date) {
        guard let user = authService.currentUser else { return }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        
        let descriptor = FetchDescriptor<VideoSchedule>(
            predicate: #Predicate<VideoSchedule> { s in
                s.scheduledDate >= start &&
                s.isTemplate == false
            }
        )
        
        let all = (try? settingsVM.modelContext.fetch(descriptor)) ?? []
        existingScheduleCount = all.filter { $0.user?.id == user.id }.count
        
        if existingScheduleCount > 0 {
            showMergeDialog = true
        }
    }
    
    // dayTab — mit Minuten und ausgegraut wenn inaktiv:
    private func dayTab(_ day: WeekDay) -> some View {
        let isSelected = selectedDayIndex == day.dayNumber
        let hasVideos = hasVideos(for: day.dayNumber)
        let minutes = targetMinutes(for: day.dayNumber)
        let isActive = minutes > 0
        let planned = plannedMinutes(for: day.dayNumber)
        let progress = isActive ? min(Double(planned) / Double(minutes), 1.0) : 0.0
        let isOver = planned > minutes
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDayIndex = day.dayNumber
            }
        } label: {
            VStack(spacing: 4) {
                Text(day.shortName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(
                        isSelected ? .white : (isActive ? .primary : .secondary)
                    )
                
                Text(isActive ? "\(minutes) Min" : "–")
                    .font(.caption2)
                    .foregroundColor(
                        isSelected ? .white.opacity(0.8) :
                        isActive ? .accent : .secondary
                    )
                
                // ✅ Fortschrittsbalken nur bei Weekly
                if rule == .weekly && isActive {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                                .frame(height: 3)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    isOver ? Color.red :
                                    progress >= 1.0 ? Color.green :
                                    isSelected ? Color.white : Color.accent
                                )
                                .frame(width: geo.size.width * progress, height: 3)
                        }
                    }
                    .frame(height: 3)
                } else {
                    // Bei Daily: nur Indikator-Punkt
                    Circle()
                        .fill(hasVideos ? Color.green : Color.clear)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(
                                    hasVideos ? Color.green : Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                }
            }
            .frame(minWidth: 44)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected ? Color.accent :
                        isActive ? Color.gray.opacity(0.1) :
                        Color.gray.opacity(0.05)
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(isActive ? 1.0 : 0.5)
    }
    
    // MARK: - Day Video List
    private var dayVideoList: some View {
        ScrollView {
            VStack(spacing: 12) {
                let videos = weekPlan[selectedDayIndex] ?? []
                
                // dayVideoList — Empty State mit Hinweis für inaktive Tage:
                if videos.isEmpty {
                    VStack(spacing: 12) {
                        if !isActiveDay(selectedDayIndex) {
                            Image(systemName: "moon.zzz")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Kein Training für \(WeekDay.allCases.first { $0.dayNumber == selectedDayIndex }?.fullName ?? "")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("In den Settings wurde für diesen Tag kein Training eingeplant.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Image(systemName: "video.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Keine Videos für \(WeekDay.allCases.first { $0.dayNumber == selectedDayIndex }?.fullName ?? "")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                
                } else {
                    ForEach(videos) { planned in
                        plannedVideoRow(planned, dayIndex: selectedDayIndex)
                    }
                }

                
                
                // + Video hinzufügen
                Button {
                    showLibrary = true
                } label: {
                    Label("Video hinzufügen", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                minutesSummary
            }
            .padding(.vertical, 16)
        }
    }
    
    private func plannedVideoRow(_ planned: PlannedVideo, dayIndex: Int) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accent.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "play.fill")
                        .foregroundColor(.accent)
                        .font(.caption)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(planned.video.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Label("\(planned.repetitions)×", systemImage: "repeat")
                    Label("\(planned.loopDurationSeconds / 60) Min", systemImage: "timer")
                    Label("\(planned.pauseSeconds)s Pause", systemImage: "pause.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Löschen
            Button {
                weekPlan[dayIndex]?.removeAll { $0.id == planned.id }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        VStack(spacing: 8) {
            
            // ✅ Zusammenfassung je nach Regel
            if rule == .daily {
                let count = weekPlan[0]?.count ?? 0
                Text("\(count) Videos · täglich an \(activeDays.count) Trainingstagen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                let plannedDays = weekPlan.filter { !$0.value.isEmpty }.count
                let totalVideos = weekPlan.values.flatMap { $0 }.count
                Text("\(plannedDays) Tage geplant · \(totalVideos) Videos gesamt")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button {
                onSave(startDate, weekPlan, mergeStrategy)
            } label: {
                Label("Plan speichern", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isReadyToSave ? Color.accent : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
            }
            .disabled(!isReadyToSave)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(Color(.systemGroupedBackground))
    }

    // ✅ Computed Property für Save-Button Aktivierung
    private var isReadyToSave: Bool {
        if rule == .daily {
            return !(weekPlan[0]?.isEmpty ?? true)
        } else {
            return weekPlan.values.contains { !$0.isEmpty }
        }
    }
    
    
}
