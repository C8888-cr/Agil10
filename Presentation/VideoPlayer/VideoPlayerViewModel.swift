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
    @Published private(set) var isLoading = false
    @Published private(set) var isPlaying = false
    @Published private(set) var showControls = true
    @Published var isFullscreen = false
    @Published var settings: PlaybackSettings
    @Published private(set) var trainingProgress: TrainingProgress?
    @Published var showError = false
    @Published var error: Error?
    @Published private(set) var watchProgress: Double = 0.0 //für ProgressRing
    @Published var showRatingSheet = false
 
    @Published var showFeedbackScaleSheet = false
    
    // MARK: - Private Properties
    private var lastUpdateTime = Date()
    private var playStartTime: Date?
    private var hasReachedLoopEnd = false
    
    let playerService: AVPlayerService
    let video: Video
    private let fileService: VideoFileService
    private let progressViewModel: ProgressViewModel?
    private let scheduleId: UUID?

    private let completionStyle: SessionCompletionStyle
    private var cancellables = Set<AnyCancellable>()
    private var controlsTimer: Timer?
    private var pauseTimer: Timer?
    private var dismissAction: (() -> Void)?
    private var lastLoggedTime: Int = -1
    
    private var trainingCompleted = false
    
    private let session: SessionManager
    var onVideoCompleted: (() -> Void)?

    // MARK: - Computed Properties
    var formattedCurrentTime: String {
        formatTime(playerService.progress.currentTime)
    }
    
    var formattedDuration: String {
        formatTime(playerService.progress.duration)
    }
    // ✅ NEU: Loop-Dauer aus Schedule holen (schon vorhanden in settings!)
       var currentLoopDuration: TimeInterval {
           TimeInterval(settings.loopDurationSeconds)
       }
       
       // ✅ NEU: Progress innerhalb des aktuellen Loops (0.0 - 1.0)
       var loopProgress: Double {
           guard currentLoopDuration > 0 else { return 0 }
           
           // Modulo für Loop-Position
           let timeInLoop = totalPlayTime.truncatingRemainder(dividingBy: currentLoopDuration)
           return min(1.0, max(0.0, timeInLoop / currentLoopDuration))
       }
       
       // ✅ NEU: Formatierte Zeit für Loop
       var loopTimeText: String {
           let timeInLoop = totalPlayTime.truncatingRemainder(dividingBy: currentLoopDuration)
           return "\(formatTime(timeInLoop)) / \(formatTime(currentLoopDuration))"
       }
       
       // ✅ NEU: Aktueller Loop Index (1, 2, 3, ...)
       var currentLoopIndex: Int {
           guard currentLoopDuration > 0 else { return 1 }
           return Int(totalPlayTime / currentLoopDuration) + 1
       }
    
    // MARK: - Initialization
    init(video: Video,
         scheduleId: UUID? = nil,
         progressViewModel: ProgressViewModel? = nil,
         session: SessionManager,
         completionStyle: SessionCompletionStyle = .starRating,
         onComplete: (() -> Void)? = nil
    ) {
        self.session = session
        self.scheduleId = scheduleId
        self.completionStyle = completionStyle
        self.progressViewModel = progressViewModel
        self.video = video
        self.playerService = AVPlayerService()
        self.fileService = VideoFileService()
        self.onVideoCompleted = onComplete
        
        // Settings aus Schedule oder Video-Defaults
           if let scheduleId = scheduleId,
              let progressVM = progressViewModel,
              let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }) {

               print("🔍 Schedule DEBUG:")
               print("  effectiveRepetitions: \(schedule.effectiveRepetitions)")
               print("  effectivePauseSeconds: \(schedule.effectivePauseSeconds)")
               print("  effectiveLoopDurationSeconds: \(schedule.effectiveLoopDurationSeconds)")
               print("  video.durationSeconds: \(video.durationSeconds)")

                self.settings = PlaybackSettings(
                    mode: .training,  // ← AUTOMATISCH TRAINING!
                    speed: .normal,
                    repetitions: schedule.effectiveRepetitions,
                    pauseSeconds: schedule.effectivePauseSeconds,
                    volume: 1.0,
                    isMuted: false,
                    loopDurationSeconds: schedule.effectiveLoopDurationSeconds)
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
        setupObservers()
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
                
                
                try await waitForPlayerReady()
   
            
                playerService.play()
                isPlaying = true
                UIApplication.shared.isIdleTimerDisabled = true
                
                
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
    
    // ✅ NEU: Warte bis Player bereit ist
    private func waitForPlayerReady() async throws {
        guard let player = playerService.player else {
            throw VideoError.playerNotReady
        }
        
        // Warte max. 3 Sekunden auf "readyToPlay"
        for _ in 0..<30 {
            if player.currentItem?.status == .readyToPlay {
                print("✅ Player bereit!")
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        
        throw VideoError.playerNotReady
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
        resetLoopTracking()
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
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
            
            if showControls && isPlaying {
                hideControlsAfterDelay()
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
        
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = true
            }
            if isPlaying {
                hideControlsAfterDelay()
            }
        }
    
    
    // MARK: - Training Mode
    
    private func initializeTrainingMode() {
        resetLoopTracking()

        trainingProgress = TrainingProgress(
            totalRepetitions: settings.repetitions,
            currentRepetition: 1,
            isInPause: false,
            remainingPauseSeconds: 0
        )
        currentRepetition = 1
        print("🎯 Training gestartet: 1/\(settings.repetitions)")

    }
    
    // ✅ NEUE METHODE: Zentrale Loop-Reset-Logik
       private func resetLoopTracking() {
           totalPlayTime = 0.0
           lastUpdateTime = Date()
           playStartTime = nil
           hasReachedLoopEnd = false
           print("🔄 Loop-Tracking zurückgesetzt")
       }
    
    // ✅ VEREINFACHTE Loop-Ende-Behandlung
       private func handleLoopEnd() {
           guard !hasReachedLoopEnd else {
               print("⚠️ Loop-Ende bereits verarbeitet!")
               return
           }
           
           hasReachedLoopEnd = true
           playerService.pause()
           isPlaying = false
           
           print("🏁 Loop-Ende: \(Int(totalPlayTime))s / \(Int(settings.loopDurationSeconds))s")
           
           guard settings.mode == .training,
                 var progress = trainingProgress else {
               print("✅ Normal Mode - schließe View")
               dismissAction?()
               return
           }
           
           print("📊 Wiederholung \(progress.currentRepetition)/\(settings.repetitions)")
           
           if progress.currentRepetition < settings.repetitions {
               // Pause starten
               progress.isInPause = true
               progress.remainingPauseSeconds = settings.pauseSeconds
               trainingProgress = progress
               isInPause = true
               
               print("⏸️ Pause: \(settings.pauseSeconds)s")
               startPauseTimer()
               
           } else {
               // Training beendet
               completeTraining()
           }
       }
    
    
    

    // ✅ NEUE METHODE: Training abschließen
      private func completeTraining() {
          trainingCompleted = true
          print("✅ Training beendet - alle \(settings.repetitions) Wiederholungen")
          
          // Schedule als completed markieren
          if let scheduleId = scheduleId,
             let progressVM = progressViewModel,
             let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }),
             let user = session.currentUser {
              
              let videoTitle = schedule.video?.title ?? "Unbekannt"
              print("✅ Markiere Schedule '\(videoTitle)' als completed")
              progressVM.markCompletedSchedule(schedule, for: user)
          }
          // ← PlayAll-Modus: kein RatingSheet, direkt weiter
          if onVideoCompleted != nil {
                      onVideoCompleted?()     // ← DANN goToNext (nach dismiss!)
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
              print("▶️ Pause beendet - starte Rep \(progress.currentRepetition + 1)/\(settings.repetitions)")
              
              // Nächste Wiederholung
              progress.currentRepetition += 1
              progress.isInPause = false
              trainingProgress = progress
              currentRepetition = progress.currentRepetition
              isInPause = false
              
              // Loop-Tracking zurücksetzen
              resetLoopTracking()
              
              // Video neu starten
              playerService.seek(to: 0)
              
              // ✅ Kurze Verzögerung vor Play (verhindert Race Condition)
              Task {
                  try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                  playerService.play()
                  isPlaying = true
              }
              
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
                 isPlaying = false
                 print("🎬 Video-Ende erkannt bei totalPlayTime: \(String(format: "%.1f", totalPlayTime))s")
                 
                 // ✅ Nur wenn Training/Loop aktiv UND Loop nicht erreicht
                 guard (settings.mode == .training || settings.mode == .loop),
                       !hasReachedLoopEnd else {
                     print("   → Kein Restart (Mode: \(settings.mode), hasReachedLoopEnd: \(hasReachedLoopEnd))")
                     return
                 }
                 
                 // ✅ Loop-Dauer bereits erreicht?
                 if totalPlayTime >= TimeInterval(settings.loopDurationSeconds) - 0.5 {
                     print("⏹️ → Loop-Dauer erreicht (\(String(format: "%.1f", totalPlayTime))s) → STOPPEN")
                     handleLoopEnd()
                 }
                 // ✅ Video muss neu starten
                 else {
                     print("🔄 → Loop noch nicht voll (\(String(format: "%.1f", totalPlayTime))s < \(settings.loopDurationSeconds)s)")
                     print("   📹 Video neu starten...")
                     
                     Task { @MainActor in
                         playerService.seek(to: .zero)
                         try? await Task.sleep(nanoseconds: 100_000_000)
                         print("   📞 Calling play()...")
                         playerService.play()
                         isPlaying = true
                         playStartTime = Date()
                         print("▶️ Video neu gestartet (state: \(playerService.state))")
                     }
                 }
              
          case .failed(let error):
              self.error = error
              self.showError = true
              isPlaying = false
          default:
              break
          }
      }

    
    // ✅ EINE METHODE - mit TodayViewModel Integration


      
    // ✅ OPTIMIERTE Progress-Update-Logik
    private func handleProgressUpdate(_ progress: VideoProgress) {
        
        let roundedTime = Int(totalPlayTime)
          if roundedTime % 2 == 0 && roundedTime != lastLoggedTime {
              print("🆕 handleProgressUpdate")
              print("   state: \(playerService.state)")
              print("   hasReachedLoopEnd: \(hasReachedLoopEnd)")
              print("   totalPlayTime: \(String(format: "%.1f", totalPlayTime))s / \(settings.loopDurationSeconds)s")
              lastLoggedTime = roundedTime
          }
        
        guard !(trainingProgress?.isInPause ?? false) else {
            return
        }
        
        let now = Date()
        let delta = now.timeIntervalSince(lastUpdateTime)
        
        // Zeit addieren wenn Playing
        if playerService.state == .playing {
            if playStartTime == nil {
                playStartTime = now
            }
            totalPlayTime += delta
        }
        
        lastUpdateTime = now
        
        // ✅ DEBUG: Zeit-Tracking (nur alle 5s)
      
        if roundedTime % 5 == 0 && roundedTime > 0 && roundedTime != lastLoggedTime {
            print("⏱️ totalPlayTime: \(roundedTime)s / \(settings.loopDurationSeconds)s")
            lastLoggedTime = roundedTime
        }
        
        // ========================================
        // 1️⃣ Video-Ende erreicht?
        // ========================================
        if playerService.state == .ended && !hasReachedLoopEnd {
            print("🎬 Video-Ende bei \(String(format: "%.1f", totalPlayTime))s")
            print("   Loop-Dauer: \(settings.loopDurationSeconds)s")
            print("   Video-Dauer: \(Int(progress.duration))s")
            
            // Hat Loop-Dauer SCHON erreicht? (mit 0.5s Toleranz)
            if totalPlayTime >= TimeInterval(settings.loopDurationSeconds) - 0.5 {
                print("⏹️ → Loop-Dauer erreicht (\(String(format: "%.1f", totalPlayTime))s >= \(settings.loopDurationSeconds)s) → PAUSE")
                handleLoopEnd()
                return
            }
            // Noch nicht → Video neu starten
            else {
                print("🔄 → Loop noch nicht voll (\(String(format: "%.1f", totalPlayTime))s < \(settings.loopDurationSeconds)s)")
                print("   Video neu starten...")
                
                playerService.seek(to: .zero)
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    playerService.play()
                    playStartTime = now
                    print("▶️ Video neu gestartet")
                }
                return
            }
        }
        
        // ========================================
        // 2️⃣ Loop-Dauer WÄHREND Playback erreicht
        // ========================================
        // (Für Videos LÄNGER als Loop-Dauer)
        if totalPlayTime >= TimeInterval(settings.loopDurationSeconds) &&
           !hasReachedLoopEnd &&
           playerService.state == .playing {
            print("⏹️ Loop-Dauer während Playback erreicht: \(Int(totalPlayTime))s → STOPPEN")
            handleLoopEnd()
            return
        }
        
        // ========================================
        // 3️⃣ UI Progress Update
        // ========================================
        let ratio = progress.duration > 0 ? progress.currentTime / progress.duration : 0.0
        watchProgress = min(1.0, max(0.0, ratio))
        
        progressViewModel?.updateVideoProgress(
            for: video.id.uuidString,
            progress: watchProgress
        )
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        UIApplication.shared.isIdleTimerDisabled = false
        trainingCompleted = false
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
    
    // ✅ Rating speichern
       func saveRating(_ rating: Int) {
           print("⭐️ Rating gespeichert: \(rating)")
           
           if let scheduleId = scheduleId,
              let progressVM = progressViewModel,
              let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }),
               let user = session.currentUser {
               
               // ✅ Rating setzen
               schedule.rating = rating
               
               // ✅ Als completed markieren
          //     progressVM.markCompletedSchedule(schedule, for: user)
               //dopplung mit completeTraining
               progressVM.updateSchedule(schedule, for: user)
               print("✅ Schedule '\(schedule.video?.title ?? "Unknown")' completed mit Rating \(rating)")
           }
           
           // View schließen
           showRatingSheet = false
           dismissAction?()
       }
    
    // NEU:
        //  Mobility-Feedback speichern
        func saveFeedbackScale(_ value: Double) {
            if let scheduleId = scheduleId,
               let progressVM = progressViewModel,
               let schedule = progressVM.todaysSchedules.first(where: { $0.id == scheduleId }),
               let user = session.currentUser {
                schedule.mobilityFeedback = min(1.0, max(0.0, value))
                progressVM.updateSchedule(schedule, for: user)
                print("📊 Mobility-Feedback gespeichert: \(value)")
            }
            showFeedbackScaleSheet = false
            dismissAction?()
        }
    
    
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
