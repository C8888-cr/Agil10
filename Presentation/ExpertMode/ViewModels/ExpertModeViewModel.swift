
import Foundation
import Combine
import AVFoundation

@MainActor
final class ExpertModeViewModel: ObservableObject {

    // MARK: - Published
    @Published private(set) var state: WorkoutSessionState = .idle
    @Published private(set) var totalWeightKg: Int = 0
    @Published private(set) var showPlusPopup: Bool = false
    @Published var weightKg: Int
    @Published var showRatingSheet: Bool = false
    @Published var showFeedbackScaleSheet: Bool = false
    
    
    /// Ob das Trainingsvideo neben der Pille angezeigt wird.
    /// Single Source of Truth für die Video-Sichtbarkeit.
    @Published private(set) var isVideoVisible: Bool
    /// Ob das Trainingsvideo im Hochformat (Portrait) gefilmt wurde.
        /// Wird beim Erscheinen asynchron aus dem AVAsset ermittelt.
        /// Default true = Hochformat (häufigster Fall), bis geklärt.
        @Published private(set) var isPortraitVideo: Bool = true
    // MARK: - Context
    let video: Video
    let videoTitle: String
    let modus: WorkoutModus
    let lastTrainingTotalKg: Int?

    /// Steuert, wie sich das Video während des Trainings verhält.
    let videoDuringTraining: VideoDuringTrainingMode
    /// Bestimmt, welches Abschluss-Sheet nach der Session erscheint.
    let completionStyle: SessionCompletionStyle
    
    
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

    // MARK: - Video Display Helpers

    /// Ob überhaupt ein Video-Bereich existiert (alwaysOn oder toggleable).
    var isVideoFeatureEnabled: Bool {
        videoDuringTraining != .alwaysOff
    }

    /// Ob der Nutzer das Video aus-/einblenden darf (nur bei toggleable).
    var canToggleVideo: Bool {
        videoDuringTraining == .toggleable
    }

   

    /// Video soll abspielen, solange es sichtbar ist und keine Pause läuft.
    var isVideoPlaying: Bool {
        isVideoVisible && !isInRest
    }

    init(
        video: Video,
        tempoProtocol: TempoProtocol,
        weightKg: Int = 0,
        lastTrainingTotalKg: Int? = nil,
        videoDuringTraining: VideoDuringTrainingMode = .toggleable,
        completionStyle: SessionCompletionStyle = .starRating,
        setsOverride: Int? = nil,
        repsOverride: Int? = nil,
        restOverride: Int? = nil,
        scheduleId: UUID? = nil,
        progressViewModel: ProgressViewModel? = nil,
        session: SessionManager? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        self.video = video
        self.videoTitle = video.title
        self.weightKg = weightKg
        self.lastTrainingTotalKg = lastTrainingTotalKg
        self.videoDuringTraining = videoDuringTraining
        self.completionStyle = completionStyle
        self.modus = WorkoutModus.matching(tempoProtocol)
        self.scheduleId = scheduleId
        self.progressViewModel = progressViewModel
        self.session = session
        self.onWorkoutCompleted = onComplete

        // Startzustand des Videos abhängig vom Modus:
        // alwaysOn / toggleable starten sichtbar, alwaysOff bleibt aus.
        self.isVideoVisible = (videoDuringTraining != .alwaysOff)

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

    // MARK: - Video Actions

    /// Schaltet das Video ein/aus (nur erlaubt bei .toggleable).
        func toggleVideo() {
            guard canToggleVideo else { return }
            isVideoVisible.toggle()
        }
    
    
    /// Liest das Seitenverhältnis der Videodatei aus und setzt
        /// isPortraitVideo. Asynchron — dauert nur Sekundenbruchteile.
        func detectVideoOrientation() async {
            let fileService = VideoFileService()
            guard let url = fileService.getVideoURL(for: video.videoFileName) else {
                print("⚠️ detectVideoOrientation: Video-URL nicht gefunden")
                return
            }

            let asset = AVURLAsset(url: url)
            do {
                guard let track = try await asset.loadTracks(withMediaType: .video).first else {
                    print("⚠️ detectVideoOrientation: keine Videospur gefunden")
                    return
                }
                let naturalSize = try await track.load(.naturalSize)
                let transform = try await track.load(.preferredTransform)

                // Transform auf die Größe anwenden → tatsächlich sichtbare Maße.
                let resolution = naturalSize.applying(transform)
                let width = abs(resolution.width)
                let height = abs(resolution.height)

                let portrait = height >= width
                isPortraitVideo = portrait

                print("🎬 Video-Format: \(width)x\(height) → \(portrait ? "HOCHFORMAT" : "QUERFORMAT")")
            } catch {
                print("⚠️ detectVideoOrientation Fehler: \(error.localizedDescription)")
            }
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

        // PlayAll-Modus: direkt weiter, kein Abschluss-Sheet
               if onWorkoutCompleted != nil {
                   onWorkoutCompleted?()
                   return
               }

               // Einzel-Modus: Abschluss-Sheet je nach Modus
               switch completionStyle {
               case .starRating:
                   showRatingSheet = true
               case .feedbackScale:
                   showFeedbackScaleSheet = true
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
    
    //  Mobility-Feedback speichern
    func saveFeedbackScale(_ value: Double) {
        if let scheduleId,
           let progressVM = progressViewModel,
           let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }),
           let user = session?.currentUser {
            schedule.mobilityFeedback = min(1.0, max(0.0, value))
            progressVM.updateSchedule(schedule, for: user)
            print("📊 Mobility-Feedback gespeichert: \(value)")
        }
        showFeedbackScaleSheet = false
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
