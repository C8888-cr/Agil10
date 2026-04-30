//
//  ExpertModeViewModel.swift
//  Agil
//

import Foundation
import Combine

@MainActor
final class ExpertModeViewModel: ObservableObject {
    
    // MARK: - Published
    @Published private(set) var state: WorkoutSessionState = .idle
    @Published private(set) var totalWeightKg: Int = 0
    @Published private(set) var showPlusPopup: Bool = false
    @Published var weightKg: Int
    @Published var showRatingSheet: Bool = false
    
    // MARK: - Context
    let videoTitle: String
    let modus: WorkoutModus
    let lastTrainingTotalKg: Int?
    
    //  Für Completion-Tracking
    private let scheduleId: UUID?
    private weak var progressViewModel: ProgressViewModel?
    private let session: SessionManager?
    var onWorkoutCompleted: (() -> Void)?
    
    // MARK: - Dependencies
    private let useCase: WorkoutSessionUseCase
    private var cancellables = Set<AnyCancellable>()
    
    private var lastProcessedTotalReps: Int = 0
    private var popupDismissTask: Task<Void, Never>?
    private var hasMarkedComplete: Bool = false
    
    // MARK: - Convenience
    var totalSets: Int { useCase.protocolSnapshot.sets }
    var totalReps: Int { useCase.protocolSnapshot.reps }
    
    init(
        videoTitle: String,
        tempoProtocol: TempoProtocol,
        weightKg: Int = 0,
        lastTrainingTotalKg: Int? = nil,
        setsOverride: Int? = nil,
        repsOverride: Int? = nil,
        restOverride: Int? = nil,
        scheduleId: UUID? = nil,
        progressViewModel: ProgressViewModel? = nil,
        session: SessionManager? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        self.videoTitle = videoTitle
        self.weightKg = weightKg
        self.lastTrainingTotalKg = lastTrainingTotalKg
        self.modus = WorkoutModus.matching(tempoProtocol)
        self.scheduleId = scheduleId
        self.progressViewModel = progressViewModel
        self.session = session
        self.onWorkoutCompleted = onComplete
        self.useCase = WorkoutSessionUseCase(
            protocolSnapshot: TempoProtocolSnapshot(
                from: tempoProtocol,
                setsOverride: setsOverride,
                repsOverride: repsOverride,
                restOverride: restOverride
            )
        )
        
        bindUseCase()
    }
    
    deinit {
        popupDismissTask?.cancel()
    }
    
    private func bindUseCase() {
        useCase.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.handleStateChange(newState)
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ newState: WorkoutSessionState) {
        if case .working(let progress) = newState {
            let totalCompletedReps = (progress.currentSet - 1) * totalReps + progress.currentRep
            if totalCompletedReps > lastProcessedTotalReps {
                let newReps = totalCompletedReps - lastProcessedTotalReps
                totalWeightKg += weightKg * newReps
                lastProcessedTotalReps = totalCompletedReps
                triggerPlusPopup()
            }
        }
        
        if case .idle = newState, lastProcessedTotalReps > 0 {
            totalWeightKg = 0
            lastProcessedTotalReps = 0
        }
        
        //  Workout abgeschlossen
        if case .done = newState, !hasMarkedComplete {
            handleWorkoutCompleted()
        }
        
        state = newState
    }
    
    //  Wird gefeuert, wenn alle Sätze durch sind
    private func handleWorkoutCompleted() {
        hasMarkedComplete = true
        
        // Schedule als completed markieren
        if let scheduleId,
           let progressVM = progressViewModel,
           let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }),
           let user = session?.currentUser {
            print("✅ Markiere Expert-Schedule '\(schedule.video?.title ?? "?")' als completed")
            progressVM.markCompletedSchedule(schedule, for: user)
        }
        
        // PlayAll-Modus: direkt weiter, kein Rating
        if onWorkoutCompleted != nil {
            onWorkoutCompleted?()
        } else {
            // Einzel-Modus: Rating-Sheet zeigen
            showRatingSheet = true
        }
    }
    
    //  Rating speichern
    func saveRating(_ rating: Int) {
        if let scheduleId,
           let progressVM = progressViewModel,
           let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }),
           let user = session?.currentUser {
            schedule.rating = rating
            progressVM.updateSchedule(schedule, for: user)
            print("⭐️ Expert-Rating gespeichert: \(rating)")
        }
        showRatingSheet = false
    }
    
    private func triggerPlusPopup() {
        popupDismissTask?.cancel()
        showPlusPopup = true
        popupDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.showPlusPopup = false
            }
        }
    }
    
    // MARK: - Actions
    
    func onPrimaryButtonTapped() {
        switch state {
        case .idle:    useCase.startNextSet()
        case .working: useCase.abort()
        case .resting: useCase.skipRest()
        case .done:    break
        }
    }

    
    // MARK: - Display Helpers
    
    var primaryButtonTitle: String {
        switch state {
        case .idle:    return "Satz \(nextSetNumber) starten"
        case .working: return "Abbrechen"
        case .resting: return "Pause überspringen"
        case .done:    return "Fertig"
        }
    }
    
    var currentSetDisplay: Int {
        switch state {
        case .idle:            return nextSetNumber
        case .working(let p):  return p.currentSet
        case .resting(let p):  return min(p.completedSet + 1, p.totalSets)
        case .done:            return totalSets
        }
    }
    
    var currentRepDisplay: Int {
        if case .working(let p) = state { return p.currentRep }
        return 0
    }
    
    var ballFillRatio: Double {
        guard totalReps > 0 else { return 0 }
        return Double(currentRepDisplay) / Double(totalReps)
    }
    
    var longBarPosition: Double {
        if case .working(let p) = state {
            return p.longBarPosition
        }
        return 0.05
    }
    
    var isLongBarVisible: Bool {
        if case .working = state { return true }
        return false
    }
    
    var phaseShortLabel: String {
        switch state {
        case .working(let p):
            switch p.phase {
            case .concentric: return "Hoch"
            case .hold:       return "Halten"
            case .eccentric:  return "Runter"
            case .isometric:  return "Halten"
            }
        case .idle:    return "Bereit"
        case .resting: return "Pause"
        case .done:    return "Fertig"
        }
    }
    
    var restSecondsDisplay: Int {
        if case .resting(let p) = state { return p.secondsRemaining }
        return 0
    }
    
    var isInRest: Bool {
        if case .resting = state { return true }
        return false
    }
    
    var plusWeightText: String {
        "+\(weightKg) kg"
    }
    
    private var nextSetNumber: Int {
        if case .resting(let p) = state {
            return min(p.completedSet + 1, p.totalSets)
        }
        return 1
    }
}
