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
    
    private var hasReachedLoopEnd = false

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
        print("🔍 handleVideoEnd: Rep \(trainingProgress?.currentRepetition ?? 0)/\(settings.repetitions)")
        
        guard settings.mode == .training,
              var progress = trainingProgress else {
            print("✅ Video beendet - schließe View")
            dismissAction?()
            return
        }
        
        if progress.currentRepetition < settings.repetitions {
            print("⏸️ PAUSE starten: Rep \(progress.currentRepetition + 1)/\(settings.repetitions)")
            
            // 1. VIDEO PAUSIEREN
            playerService.pause()
            
            // 2. Pause starten
            progress.isInPause = true
            progress.remainingPauseSeconds = settings.pauseSeconds
            trainingProgress = progress
            startPauseTimer()
            
        } else {
            // ✅ Training beendet!
            print("✅ Training beendet - schließe View")
            
            // 1. User holen
            guard let user = AppDependencies.shared.authService.currentUser else {
                print("❌ Kein User - kann Schedule nicht completen")
                dismissAction?()
                return
            }
            
            // 2. Schedule completen (wenn vorhanden)
            if let scheduleId = scheduleId,
               let progressVM = progressViewModel,
               let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }) {
                
                // ✅ FIX: Optional unwrapping
                let videoTitle = schedule.video?.title ?? "Unbekannt"
                print("✅ Markiere Schedule als completed: \(videoTitle)")
                
                progressVM.markCompletedSchedule(schedule, for: user)
            }
            
            // 3. View schließen
            dismissAction?()
        }
    }
    
    
    
    // ✅ NEUE METHODE: Loop-Ende Handler
      private func handleLoopEnd() {
          guard !hasReachedLoopEnd else {
              print("⚠️ Loop-Ende bereits verarbeitet!")
              return
          }
          
          hasReachedLoopEnd = true
          
          print("🏁 Loop-Ende erreicht: \(Int(totalPlayTime))s / \(Int(settings.loopDurationSeconds))s")
          
          guard var progress = trainingProgress else {
              print("✅ Kein Training-Mode - schließe View")
              dismissAction?()
              return
          }
          
          print("📊 Rep \(progress.currentRepetition)/\(settings.repetitions)")
          
          if progress.currentRepetition < settings.repetitions {
              // ✅ Weitere Wiederholungen → PAUSE
              print("⏸️ PAUSE starten: \(settings.pauseSeconds)s")
              
              playerService.pause()
              isPlaying = false
              
              progress.isInPause = true
              progress.remainingPauseSeconds = settings.pauseSeconds
              trainingProgress = progress
              
              startPauseTimer()
              
          } else {
              // ✅ Training beendet!
              print("✅ Training beendet - alle \(settings.repetitions) Wiederholungen")
              
              if let scheduleId = scheduleId,
                 let progressVM = progressViewModel,
                 let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }),
                 let user = AppDependencies.shared.authService.currentUser {
                  
                  print("✅ Markiere Schedule als completed")
                  progressVM.markCompletedSchedule(schedule, for: user)
              }
              
              dismissAction?()
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
             print("▶️ Pause beendet - starte nächste Wiederholung")
             
             // ✅ 1. Nächste Wiederholung
             progress.currentRepetition += 1
             progress.isInPause = false
             trainingProgress = progress
             
             // ✅ 2. RESET Loop-Tracking
             totalPlayTime = 0.0
             lastUpdateTime = Date()
             playStartTime = nil
             hasReachedLoopEnd = false  // ← WICHTIG!
             
             // ✅ 3. Video neu starten
             playerService.seek(to: 0)
             playerService.play()
             isPlaying = true
             
             print("🔄 Loop \(progress.currentRepetition)/\(settings.repetitions) gestartet")
             
             pauseTimer?.invalidate()
             
         } else {
             trainingProgress = progress
         }
     }
     
    
    // MARK: - Observer Handlers
    
    private func handlePlayerStateChange(_ state: PlayerState) {
          switch state {
          case .playing:
              isPlaying = true
          case .paused:
              isPlaying = false
          case .ended:
              // ✅ Video zu Ende → aber Loop-Dauer prüft handleProgressUpdate!
              print("🔄 Video-Ende - Loop-Check läuft in handleProgressUpdate")
              isPlaying = false
          case .failed(let error):
              self.error = error
              self.showError = true
              isPlaying = false
          default:
              break
          }
      }

    
    // ✅ EINE METHODE - mit TodayViewModel Integration


      
      private func handleProgressUpdate(_ progress: VideoProgress) {
          guard !(trainingProgress?.isInPause ?? false) else {
              return
          }
          
          let now = Date()
          let delta = now.timeIntervalSince(lastUpdateTime)
          
          // ✅ Zeit addieren bei PLAYING
          if playerService.state == .playing {
              if playStartTime == nil {
                  playStartTime = now
              }
              totalPlayTime += delta
          }
          
          lastUpdateTime = now
          
          // ✅ Loop-Dauer erreicht?
          if totalPlayTime >= TimeInterval(settings.loopDurationSeconds) && !hasReachedLoopEnd {
              print("⏹️ Loop-Dauer \(Int(settings.loopDurationSeconds))s erreicht!")
              playerService.pause()
              handleLoopEnd()  // ← Ersetzt handleVideoEnd()
              return
          }
          
          // ✅ Video-Ende (innerhalb Loop-Dauer) → neu starten
          if playerService.state == .ended && totalPlayTime < TimeInterval(settings.loopDurationSeconds) {
              print("🔄 Video-Ende bei \(Int(totalPlayTime))s → Loop!")
              playerService.seek(to: .zero)
              playerService.play()
              playStartTime = now
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
