import SwiftUI
import SwiftData

struct DailyTemplateView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var videoLibraryVM: VideoLibraryViewModel
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var progressVM: ProgressViewModel
    
    let rule: RecurrenceRule  // ← NEU
    @State private var editingDayIndex: Int = 0  // ← NEU statt currentDayIndex
    @State private var showLibrary = false
    @State private var selectedVideoForConfig: Video?
    @State private var currentDayIndex: Int = 0
    @State private var showConfirmAlert = false
    
    private var templateSchedules: [VideoSchedule] {
        if rule == .daily {
            return settingsVM.dailyTemplates
        } else {
            return settingsVM.dailyTemplates.filter { $0.dayOfWeek == currentDayIndex }
        }
    }

    var body: some View {
        NavigationStack {
            if rule == .weekly {
                weeklyPagerView
            } else {
                dailyFormView
            }
        }
    }
    
    // MARK: - Weekly Pager
    private var weeklyPagerView: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentDayIndex) {
                ForEach(0..<7, id: \.self) { index in
                    weeklyDayPage(for: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            Button {
                showConfirmAlert = true
            } label: {
                Text("Wochenvorlage anwenden")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accent)
                    .cornerRadius(12)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Wochen-Vorlage")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLibrary) { librarySheet }
        .sheet(item: $selectedVideoForConfig) { video in configSheet(for: video) }
        .alert("Wochenvorlage anwenden?", isPresented: $showConfirmAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Anwenden", role: .destructive) {
                applyWeeklyTemplates()
            }
        } message: {
            Text("Alle bestehenden geplanten Videos werden ersetzt.")
        }
    }
    
    private func weeklyDayPage(for index: Int) -> some View {
        let schedules = settingsVM.dailyTemplates.filter { $0.dayOfWeek == index }
        
        return Form {
            // Tag-Header
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text(WeekDay.allCases[index].fullName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(schedules.isEmpty ? "Noch keine Videos" : "\(schedules.count) Video\(schedules.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // Videos
            Section {
                if schedules.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "video.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Wische um andere Tage zu sehen")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                } else {
                    ForEach(schedules, id: \.id) { schedule in
                        if let video = schedule.video {
                            templateVideoRow(schedule: schedule, video: video)
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet {
                            settingsVM.removeDailyTemplate(
                                schedules[i],
                                user: authService.currentUser!
                            )
                        }
                    }
                }
                
                Button {
                    editingDayIndex = index
                    DispatchQueue.main.async {
                        showLibrary = true
                    }
                } label: {
                    Label("Video hinzufügen", systemImage: "plus.circle.fill")
                        .foregroundColor(.accent)
                }
            } header: {
                Label("Videos", systemImage: "list.bullet")
            } footer: {
                if !schedules.isEmpty {
                    let total = schedules.reduce(0) { $0 + $1.totalDurationSeconds }
                    let m = total / 60
                    let s = total % 60
                    Text("Gesamtdauer: \(s > 0 ? "\(m):\(String(format: "%02d", s))" : "\(m)") Min")
                        .font(.caption)
                }
            }
        }
    }
    
    
    // MARK: - Daily Form (wie bisher)
    private var dailyFormView: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accent)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tages-Vorlage")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Diese Videos werden täglich an allen aktiven Trainingstagen angezeigt.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section {
                if templateSchedules.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "video.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Noch keine Videos")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tippe auf + um Videos hinzuzufügen")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                } else {
                    ForEach(templateSchedules, id: \.id) { schedule in
                        if let video = schedule.video {
                            templateVideoRow(schedule: schedule, video: video)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            settingsVM.removeDailyTemplate(
                                templateSchedules[index],
                                user: authService.currentUser!
                            )
                        }
                    }
                }
                
                Button {
                    showLibrary = true
                } label: {
                    Label("Video hinzufügen", systemImage: "plus.circle.fill")
                        .foregroundColor(.accent)
                }
            } header: {
                Label("Videos in der Vorlage", systemImage: "list.bullet")
            } footer: {
                if !templateSchedules.isEmpty {
                    Text("Gesamtdauer: \(totalDurationText)")
                        .font(.caption)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
               Button {
                   showConfirmAlert = true
               } label: {
                   Text("Tagesvorlage anwenden")
                       .font(.headline)
                       .foregroundColor(.white)
                       .frame(maxWidth: .infinity)
                       .padding()
                       .background(Color.accent)
                       .cornerRadius(12)
               }
               .padding()
               .background(Color(.systemGroupedBackground))
           }
           .navigationTitle("Tages-Vorlage")
           .navigationBarTitleDisplayMode(.inline)
           .sheet(isPresented: $showLibrary) { librarySheet }
           .sheet(item: $selectedVideoForConfig) { video in configSheet(for: video) }
           .alert("Tagesvorlage anwenden?", isPresented: $showConfirmAlert) {
               Button("Abbrechen", role: .cancel) { }
               Button("Anwenden", role: .destructive) {
                   applyDailyTemplates()
               }
           } message: {
               Text("Alle bestehenden geplanten Videos werden ersetzt.")
           }
       }
    
    // MARK: - Shared Sheets
    private var librarySheet: some View {
        NavigationStack {
            LibraryView(
                onVideoSelected: { video in
                    showLibrary = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedVideoForConfig = video
                    }
                }
            )
            .environmentObject(authService)
            .environmentObject(videoLibraryVM)
            .environmentObject(settingsVM)
        }
    }
    
    private func configSheet(for video: Video) -> some View {
        VideoQuickConfigSheet(
            video: video,
            onAdd: { reps, loopDuration, pause in
                if let user = authService.currentUser {
                    settingsVM.addDailyTemplate(
                        video: video,
                        repetitions: reps,
                        loopDurationSeconds: loopDuration,
                        pauseSeconds: pause,
                        dayIndex: editingDayIndex,
                        user: user
                    )
                    print("📋 Template für Tag \(editingDayIndex) hinzugefügt")
                }
                selectedVideoForConfig = nil
            },
            onCancel: {
                selectedVideoForConfig = nil
            }
        )
    }
    
    // MARK: - Helpers (wie bisher)
    private func templateVideoRow(schedule: VideoSchedule, video: Video) -> some View {
        HStack(spacing: 16) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accent.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "play.fill")
                        .foregroundColor(.accent)
                        .font(.caption)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                // Icons mit Zahlen — kompakt, kein Label-Text
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "repeat")
                            .font(.caption2)
                        Text("\(schedule.effectiveRepetitions)×")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.caption2)
                        Text("\(schedule.effectiveLoopDurationSeconds / 60)")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "pause.fill")
                            .font(.caption2)
                        Text("\(schedule.effectivePauseSeconds)")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Mülleimer
            Button {
                if let user = authService.currentUser {
                    settingsVM.removeDailyTemplate(schedule, user: user)
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    
    
    private var totalDurationText: String {
        let total = templateSchedules.reduce(0) { $0 + $1.totalDurationSeconds }
        let m = total / 60
        let s = total % 60
        return s > 0 ? "\(m):\(String(format: "%02d", s)) Min" : "\(m) Min"
    }
    private func applyDailyTemplates() {
        guard let user = authService.currentUser else { return }
        settingsVM.applyTemplatesToActiveDays(for: user, progressVM: progressVM)
    }

    private func applyWeeklyTemplates() {
        guard let user = authService.currentUser else { return }
        
        var weekPlan: [Int: [WeekPlannerSheet.PlannedVideo]] = [:]
        
        for dayIndex in 0..<7 {
            let templates = settingsVM.dailyTemplates.filter { $0.dayOfWeek == dayIndex }
            guard !templates.isEmpty else { continue }
            
            weekPlan[dayIndex] = templates.compactMap { schedule -> WeekPlannerSheet.PlannedVideo? in
                guard let video = schedule.video else { return nil }
                return WeekPlannerSheet.PlannedVideo(
                    video: video,
                    repetitions: schedule.effectiveRepetitions,
                    loopDurationSeconds: schedule.effectiveLoopDurationSeconds, pauseSeconds: schedule.effectivePauseSeconds
                )
            }
        }
        
        settingsVM.applyWeekPlan(
            startDate: Date(),
            weekPlan: weekPlan,
            rule: .weekly,
            strategy: .replaceAll,
            user: user
        )
    }
}
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Video.self, VideoSchedule.self,
        configurations: config
    )
    let context = ModelContext(container)
    
    let authService = AuthService(authServiceProtocol: MockAuthService())
    let repository = VideoScheduleRepository(modelContext: context)
      let progressVM = ProgressViewModel(authService: authService, repository: repository)
    let settingsVM = SettingsViewModel(modelContext: context, authService: authService)
    let videoLibraryVM = VideoLibraryViewModel(
        repository: VideoRepository(modelContext: context, storageService: .shared, thumbnailService: .shared),
        modelContext: context,
        authService: authService,
        storageService: .shared
    )
    
    Group {
        DailyTemplateView(rule: .daily)
            .environmentObject(settingsVM)
            .environmentObject(videoLibraryVM)
            .environmentObject(authService)
            .environmentObject(progressVM)
    }
    .modelContainer(container)
}
