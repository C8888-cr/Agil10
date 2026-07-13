//
//  KGGExercisePlayerViewModel.swift
//  Agil
//
//  Eigenständiges ViewModel für den KGG-Übungsplayer.
//  Read-only: kein Rating-Sheet, kein Feedback-Sheet, keine Gewichts-/Tempo-Änderung.
//  Video-Sichtbarkeit wird extern (KGGExerciseListView) vorgegeben, nicht hier umschaltbar.
//

import Foundation
import Combine
import AVFoundation

@MainActor
final class KGGExercisePlayerViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var state: WorkoutSessionState = .idle
    @Published private(set) var totalWeightKg: Int = 0
    @Published private(set) var showPlusPopup: Bool = false
    @Published private(set) var isPortraitVideo: Bool = true
    /// Wird true, sobald das Training abgeschlossen ist. Bool statt state-Vergleich,
    /// damit die View sicher per .onChange darauf reagieren kann (WorkoutSessionState
    /// ist ggf. nicht Equatable).
    @Published private(set) var isFinished: Bool = false

    // MARK: - Context

    let video: Video
    let weightKg: Int

    /// Wird von außen (KGGExerciseListView-Einstellung) vorgegeben — hier bewusst nicht änderbar.
    let isVideoVisible: Bool

    private let exerciseId: UUID
    private let repository: KGGExerciseRepository
    private let onComplete: (() -> Void)?

    // MARK: - Dependencies

    private let useCase: WorkoutSessionUseCase
    private var cancellables = Set<AnyCancellable>()

    private var lastProcessedTotalReps: Int = 0
    private var popupDismissTask: Task<Void, Never>?
    private var hasMarkedComplete: Bool = false

    // MARK: - Convenience

    var totalSets: Int { useCase.protocolSnapshot.sets }
    var totalReps: Int { useCase.protocolSnapshot.reps }

    /// Video soll abspielen, solange es sichtbar ist und keine Pause läuft.
    var isVideoPlaying: Bool {
        isVideoVisible && !isInRest
    }

    // MARK: - Init

    init(
        exercise: KGGScannedExercise,
        video: Video,
        isVideoVisible: Bool,
        repository: KGGExerciseRepository,
        onComplete: (() -> Void)? = nil
    ) {
        self.exerciseId = exercise.id
        self.video = video
        self.weightKg = Int(exercise.weightKg)
        self.isVideoVisible = isVideoVisible
        self.repository = repository
        self.onComplete = onComplete

        let tempoProtocol = TempoProtocol(
            concentricSec: exercise.concentricSec,
            holdSec: exercise.holdSec,
            eccentricSec: exercise.eccentricSec,
            sets: exercise.sets,
            reps: exercise.reps,
            restBetweenSetsSec: exercise.restBetweenSetsSec,
            subtype: .dynamic
        )

        self.useCase = WorkoutSessionUseCase(
            protocolSnapshot: TempoProtocolSnapshot(
                from: tempoProtocol,
                setsOverride: nil,
                repsOverride: nil,
                restOverride: nil
            )
        )

        bindUseCase()
    }

    deinit {
        popupDismissTask?.cancel()
    }

    // MARK: - Video

    /// Liest das Seitenverhältnis der Videodatei aus (Hoch-/Querformat).
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

            let resolution = naturalSize.applying(transform)
            let width = abs(resolution.width)
            let height = abs(resolution.height)

            isPortraitVideo = height >= width
        } catch {
            print("⚠️ detectVideoOrientation Fehler: \(error.localizedDescription)")
        }
    }

    // MARK: - Binding

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

        // Workout abgeschlossen → KGG-Übung als completed markieren + Callback
        if case .done = newState, !hasMarkedComplete {
            handleWorkoutCompleted()
        }

        state = newState
    }

    private func handleWorkoutCompleted() {
        hasMarkedComplete = true

        Task {
            do {
                try await repository.markCompleted(exerciseId)
            } catch {
                print("⚠️ KGG markCompleted fehlgeschlagen: \(error.localizedDescription)")
            }
        }

        onComplete?()
        isFinished = true
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
