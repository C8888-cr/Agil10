import Foundation
import AVFoundation
import Combine
import UIKit


@MainActor
final class AVPlayerService: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var player: AVPlayer?
    @Published private(set) var playerItem: AVPlayerItem?
    @Published private(set) var state: PlayerState = .idle {
        didSet { updateIdleTimer() }
    }
    @Published private(set) var progress: VideoProgress = .zero
    
    
    // MARK: - Private Properties
    
    private var timeObserver: Any?
    private var itemObserver: AnyCancellable?
    private var statusObserver: AnyCancellable?
    private var playbackFinishedObserver: AnyCancellable?
    
    // MARK: - Setup
    
    func loadVideo(from url: URL) {
        cleanup()
        
        state = .loading
        
        // AVPlayerItem erstellen
        let item = AVPlayerItem(url: url)
        playerItem = item
        
        // AVPlayer erstellen
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        
        // Observer einrichten
        setupObservers()
        
        // Audio Session konfigurieren
        configureAudioSession()
    }
    
    private func setupObservers() {
        guard let player = player, let item = playerItem else { return }
        
        // 1. Time Observer (Progress Updates)
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.updateProgress(currentTime: time)
            }
        }
        
        // 2. Status Observer
        statusObserver = item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                Task { @MainActor in
                    self?.handleStatusChange(status)
                }
            }
        
        // 3. Playback Finished Observer
        playbackFinishedObserver = NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handlePlaybackFinished()
                }
            }
        
        // 4. Buffer Observer
        itemObserver = item.publisher(for: \.isPlaybackBufferEmpty)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                Task { @MainActor in
                    if isEmpty {
                        self?.state = .buffering
                    }
                }
            }
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio Session Error: \(error)")
        }
    }
    
    // MARK: - Playback Control
    
    func play() {
        print("▶️ Play aufgerufen (State: \(state))")
        guard state != .playing else { return }
        player?.play()
        state = .playing
    }
    
    func pause() {
        print("⏸️ Pause aufgerufen")
        guard state == .playing else { return }
        player?.pause()
        state = .paused
    }
    
    func togglePlayPause() {
        if state == .playing {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func seekForward(seconds: TimeInterval = 10) {
        
        let newTime = progress.currentTime + seconds
        seek(to: min(newTime, progress.duration))
    }
    
    func seekBackward(seconds: TimeInterval = 10) {
        let newTime = progress.currentTime - seconds
        seek(to: max(newTime, 0))
    }
    
    func restart() {
        seek(to: 0)
        play()
    }
    
    func setSpeed(_ speed: PlaybackSpeed) {
        player?.rate = speed.rawValue
    }
    
    func setVolume(_ volume: Float) {
        player?.volume = volume
    }
    
    func mute() {
        player?.isMuted = true
    }
    
    func unmute() {
        player?.isMuted = false
    }
    
    // MARK: - Observer Handlers
    
    private func updateProgress(currentTime: CMTime) {
        guard let duration = playerItem?.duration else { return }
        
        let current = CMTimeGetSeconds(currentTime)
        let total = CMTimeGetSeconds(duration)
        
        guard !current.isNaN && !total.isNaN else { return }
        
        // Buffered Time
        let buffered = playerItem?.loadedTimeRanges.first.map {
            CMTimeGetSeconds(CMTimeRangeGetEnd($0.timeRangeValue))
        } ?? 0
        
        progress = VideoProgress(
            currentTime: current,
            duration: total,
            bufferedTime: buffered
        )
    }
    
    private func handleStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            state = .ready
        case .failed:
            if let error = playerItem?.error {
                state = .failed(error)
            }
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    private func handlePlaybackFinished() {
        state = .ended
    }
    
    
    
    
    // MARK: - Idle Timer

    /// Verhindert Bildschirm-Dimmen/-Sperren während der Wiedergabe.
    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = (state == .playing)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        // Observer entfernen
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        itemObserver?.cancel()
        statusObserver?.cancel()
        playbackFinishedObserver?.cancel()
        
        // Player stoppen
        player?.pause()
        player = nil
        playerItem = nil
        
        state = .idle
        progress = .zero
    }
}
