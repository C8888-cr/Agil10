//
//  VideoPlayerViewModel.swift
//  Agil
//
//  Created by Christiane Roth on 26.11.25.
//


import SwiftUI
import Combine
@MainActor
final class VideoPlayerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isInPause = false
    @Published var currentRepetition = 1
    @Published var totalPlayTime: TimeInterval = 0.0
    private var lastUpdateTime = Date()
    private var playStartTime: Date?
  
    
    @Published private(set) var isLoading = false
    @Published private(set) var isPlaying = false
    @Published private(set) var showControls = true
    @Published var isFullscreen = false
    @Published var settings: PlaybackSettings
    @Published private(set) var trainingProgress: TrainingProgress?
    @Published var showError = false
    @Published var error: Error?
    @Published private(set) var watchProgress: Double = 0.0 //für ProgressRing
    
    // MARK: - Services & Properties
    
    let playerService: AVPlayerService
    private let video: Video
    private let fileService: VideoFileService
    
    private var cancellables = Set<AnyCancellable>()
    private var controlsTimer: Timer?
    private var pauseTimer: Timer?
    private var dismissAction: (() -> Void)?
    
    private let progressViewModel: ProgressViewModel?  // ✅ NEU
    private let scheduleId: UUID?  // ✅ NEU

    // MARK: - Computed Properties
    
    var formattedCurrentTime: String {
        formatTime(playerService.progress.currentTime)
    }
    
    var formattedDuration: String {
        formatTime(playerService.progress.duration)
    }
    
    // MARK: - Initialization
    

    init(video: Video, scheduleId: UUID? = nil, progressViewModel: ProgressViewModel? = nil) {
        self.scheduleId = scheduleId  // ✅ HINZUFÜGEN!
        self.progressViewModel = progressViewModel
        self.video = video
        self.playerService = AVPlayerService()
        self.fileService = VideoFileService()
        // ← SCHEDULE SETTINGS ÜBERNEHMEN ODER VIDEO DEFAULTS!
           if let scheduleId = scheduleId,
              let progressVM = progressViewModel,
              let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }) {

               print("🔍 Schedule DEBUG:")
                      print("  effectiveRepetitions: \(schedule.effectiveRepetitions)")
                      print("  effectivePauseSeconds: \(schedule.effectivePauseSeconds)")
                      print("  effectiveLoopDurationSeconds: \(schedule.effectiveLoopDurationSeconds)")
                      print("  video.durationSeconds: \(video.durationSeconds)")


               // ✅ SCHEDULE EINSTELLUNGEN!
                      self.settings = PlaybackSettings(
                          mode: .training,  // ← AUTOMATISCH TRAINING!
                          speed: .normal,
                          repetitions: schedule.effectiveRepetitions,
                          pauseSeconds: schedule.effectivePauseSeconds,
                         
                          volume: 1.0,
                          isMuted: false,
                          loopDurationSeconds: schedule.effectiveLoopDurationSeconds,  // 30s!
                      )
                      print("✅ Schedule Settings: \(schedule.effectiveRepetitions)× \(schedule.effectivePauseSeconds)s")
                      
                  } else {
                      // Fallback zu VIDEO DEFAULTS
                            self.settings = PlaybackSettings(
                                mode: .normal,
                                speed: .normal,
                                repetitions: video.defaultRepetitions,
                                pauseSeconds: video.defaultPauseSeconds,
                                volume: 1.0,
                                isMuted: false,
                                loopDurationSeconds: 15
                            )
                        }
        setupObservers()  // ← HINZUFÜGEN! (Zeile nach settings)
                    }

    
    // MARK: - Setup
    
    private func setupObservers() {
        // Player State Observer
        playerService.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handlePlayerStateChange(state)
            }
            .store(in: &cancellables)
        
        // Progress Observer
        playerService.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.handleProgressUpdate(progress)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Video Loading
    
    func loadVideo() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                guard let videoURL = fileService.getVideoURL(for: video.videoFileName) else {
                    throw VideoError.fileNotFound
                }
                
                playerService.loadVideo(from: videoURL)
                
                // Auto-play nach laden
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s warten
                playerService.play()
                isPlaying = true
                
                // Training Mode initialisieren
                if settings.mode == .training {
                    initializeTrainingMode()
                }
                
            } catch {
                self.error = error
                self.showError = true
            }
        }
    }
    
    // MARK: - Playback Control
    
    func togglePlayPause() {
        playerService.togglePlayPause()
        isPlaying = playerService.state == .playing
        
        if isPlaying {
            hideControlsAfterDelay()
        }
    }
    
    func play() {
        playerService.play()
        isPlaying = true
        hideControlsAfterDelay()
    }
    
    func pause() {
        playerService.pause()
        isPlaying = false
        controlsTimer?.invalidate()
    }
    
    func seek(to time: TimeInterval) {
        playerService.seek(to: time)
    }
    
    func seekForward() {
        playerService.seekForward()
        resetControlsTimer()
    }
    
    func seekBackward() {
        playerService.seekBackward()
        resetControlsTimer()
    }
    
    func restart() {
        playerService.restart()
        isPlaying = true
        resetControlsTimer()
        
        if settings.mode == .training {
            initializeTrainingMode()
        }
    }
    
    // MARK: - Settings
    
    func setMode(_ mode: PlaybackMode) {
        settings.mode = mode
        
        switch mode {
        case .normal:
            trainingProgress = nil
            pauseTimer?.invalidate()
        case .training:
            initializeTrainingMode()
        case .loop:
            break
        }
    }
    
    func setSpeed(_ speed: PlaybackSpeed) {
        settings.speed = speed
        playerService.setSpeed(speed)
    }
    
    func toggleMute() {
        settings.isMuted.toggle()
        if settings.isMuted {
            playerService.mute()
        } else {
            playerService.unmute()
        }
    }
    
    // MARK: - Controls UI
    
    func toggleControls() {
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
            
            if showControls && isPlaying {
                hideControlsAfterDelay()
            }
        }
    }
    
    private func hideControlsAfterDelay() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.showControls = false
                }
            }
        }
    }
    
    private func resetControlsTimer() {
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = true
            }
            if isPlaying {
                hideControlsAfterDelay()
            }
        }
    }
    
    // MARK: - Training Mode
    
    private func initializeTrainingMode() {
        totalPlayTime = 0.0      // ✅ RESET!
            lastUpdateTime = Date()  // ✅ RESET!
            playStartTime = nil      // ✅ RESET!
        
        
        
        trainingProgress = TrainingProgress(
            totalRepetitions: settings.repetitions,
            currentRepetition: 1,
            isInPause: false,
            remainingPauseSeconds: 0
        )
        print("🎯 Training gestartet: 1/\(settings.repetitions)")

    }
    
    private func handleVideoEnd() {
        
        
        
        print("🔍 handleVideoEnd: Rep \(trainingProgress?.currentRepetition ?? 0)/\(settings.repetitions)")  // DEBUG!
        
        
        guard settings.mode == .training,
              var progress = trainingProgress else {
            print("✅ Video beendet - schließe View")
            dismissAction?()
            return
        }
        
        
        if progress.currentRepetition < settings.repetitions {
            print("⏸️ PAUSE starten: Rep \(progress.currentRepetition + 1)/\(settings.repetitions)")
            
            
            // ✅ 1. VIDEO PAUSIEREN!
            playerService.pause()
            
            // 2. Pause starten
            progress.isInPause = true
            progress.remainingPauseSeconds = settings.pauseSeconds
            trainingProgress = progress
            startPauseTimer()
        } else {
            // Training beendet → schließen
            print("✅ Training beendet - schließe View")
            if let scheduleId = scheduleId {
                progressViewModel?.completeSchedule(scheduleId: scheduleId)  // ✅ HIER!
                dismissAction?()
            }
        }
    }
    private func startPauseTimer() {
        pauseTimer?.invalidate()
        
        pauseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                self?.updatePauseTimer()
            }
        }
    }
    
    private func updatePauseTimer() {
        guard var progress = trainingProgress,
              progress.isInPause else {
            pauseTimer?.invalidate()
            return
        }
        
        progress.remainingPauseSeconds -= 1
        
        if progress.remainingPauseSeconds <= 0 {
            // ✅ 1. Nächste Wiederholung            progress.currentRepetition += 1
            progress.currentRepetition += 1
            progress.isInPause = false
            trainingProgress = progress
            
            // 2. VIDEO SIMPLE PLAY (nicht restart!)
                  playerService.seek(to: 0)
                  playerService.play()
                  isPlaying = true
            
            
            pauseTimer?.invalidate()
            
         
        } else {
            trainingProgress = progress
        }
    }
    
    // MARK: - Observer Handlers
    
    private func handlePlayerStateChange(_ state: PlayerState) {
        print("🔍 PlayerState: \(state)")  // ← HINZUFÜGEN!
        
        switch state {
        case .playing:
            print("▶️ Playing")
            isPlaying = true
        case .paused:
            print("⏸️ Paused")
            isPlaying = false
        case .ended:
            print("🔄 ENDED | Total: \(Int(totalPlayTime))s / \(Int(settings.loopDurationSeconds))s")
            
            // ✅ LOOP wenn unter Target!
            if totalPlayTime < TimeInterval(settings.loopDurationSeconds) {
                print("🔄 LOOP → Seek + Play!")
                playerService.seek(to: .zero)
                playerService.play()
                return  // ← handleVideoEnd() BLOCKIEREN!
            }
            
            print("✅ LOOP FERTIG → Training-Ende!")
            isPlaying = false
            handleVideoEnd()

        case .failed(let error):
            print("❌ Failed: \(error)")
            self.error = error
            self.showError = true
            isPlaying = false
        default:
            print("🔄 Other: \(state)")
        }
    }

    
    // ✅ EINE METHODE - mit TodayViewModel Integration


    private func handleProgressUpdate(_ progress: VideoProgress) {
        guard !(trainingProgress?.isInPause ?? false) else {
            print("⏸️ PAUSE aktiv - Loop ignoriert!")
            return
        }
        
        let now = Date()
        let delta = now.timeIntervalSince(lastUpdateTime)
        
        // ✅ 1. Bei PLAYING: totalPlayTime += delta
        if playerService.state == .playing {
            if playStartTime == nil {
                playStartTime = now  // Play-Start merken
            }
            totalPlayTime += delta
        }
        
        lastUpdateTime = now
        
        print("🔍 LOOP: Current=\(Int(progress.currentTime))s | Total=\(Int(totalPlayTime))s | Target=\(Int(settings.loopDurationSeconds))s")
        
        // ✅ 2. Loop-Dauer erreicht → ENDE!
        if totalPlayTime >= TimeInterval(settings.loopDurationSeconds) {
            print("⏹️ LOOP \(Int(settings.loopDurationSeconds))s erreicht!")
            playerService.pause()
            handleVideoEnd()
            playStartTime = nil
            return
        }
        
        // ✅ 3. Video-Ende → LOOP!
        if playerService.state == .ended {
            print("🔄 Video-Ende → Seek to 0s! Total: \(Int(totalPlayTime))s")
            playerService.seek(to: .zero)
            playStartTime = now  // Nach Seek: Zeit weiterlaufen
            return
        }
        
        // UI Progress
        let ratio = progress.duration > 0 ? progress.currentTime / progress.duration : 0.0
        watchProgress = min(1.0, max(0.0, ratio))
        
        progressViewModel?.updateVideoProgress(for: video.id.uuidString, progress: watchProgress)
    }

    
    // MARK: - Cleanup
    
    func cleanup() {
        controlsTimer?.invalidate()
        pauseTimer?.invalidate()
        cancellables.removeAll()
        playerService.cleanup()
        
        // ✅ Final Progress speichern
        progressViewModel?.updateVideoProgress(
            for: video.id.uuidString,
            progress: watchProgress
        )
    }
    
    // ✅ Dismiss-Action setzen
    func setDismissAction(_ action: @escaping () -> Void) {
        self.dismissAction = action
    }
    
    func videoDidFinish() {
        watchProgress = 1.0
        progressViewModel?.updateVideoProgress(for: video.id.uuidString, progress: 1.0)
        dismissAction?()
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
