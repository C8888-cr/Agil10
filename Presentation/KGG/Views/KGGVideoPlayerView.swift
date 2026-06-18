
//
//  KGGVideoPlayerView.swift
//  Agil10.0
//
//  Minimaler Player für verschlüsselte KGG-Videos (Art 2).
//  Nutzt KGGAssetResourceLoader für sicheres Streaming-Playback.
//  Kein Training-Logik, nur Abspielen.
//

import SwiftUI
import AVKit
import CryptoKit

struct KGGVideoPlayerView: View {
    @StateObject private var viewModel: KGGVideoPlayerViewModel
    @Environment(\.dismiss) private var dismiss

    let title: String
    let encryptedFileURL: URL
    let decryptionKey: SymmetricKey

    init(
        title: String,
        encryptedFileURL: URL,
        decryptionKey: SymmetricKey
    ) {
        self.title = title
        self.encryptedFileURL = encryptedFileURL
        self.decryptionKey = decryptionKey
        _viewModel = StateObject(wrappedValue: KGGVideoPlayerViewModel(
            encryptedFileURL: encryptedFileURL,
            decryptionKey: decryptionKey
        ))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = viewModel.player {
                // Video Player
                PlayerViewController(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.toggleControls()
                    }

                // Controls Overlay
                if viewModel.showControls {
                    VStack(spacing: 0) {
                        // Top: Close Button + Title
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text("Streaming verschlüsselt")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }

                            Spacer()
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.black.opacity(0.6), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        Spacer()

                        // Bottom: Progress Bar
                        VStack(spacing: 12) {
                            progressBar

                            HStack(spacing: 16) {
                                Text(viewModel.currentTimeText)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .monospacedDigit()

                                Spacer()

                                Text(viewModel.durationText)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .monospacedDigit()
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .transition(.opacity)
                }
            } else if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            }
        }
        .navigationBarHidden(true)
        .keepScreenAwake()
        .onAppear {
            viewModel.setupPlayer()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)

                // Progress
                if viewModel.duration > 0 {
                    Capsule()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * (viewModel.currentTime / viewModel.duration), height: 4)
                }
            }
            .frame(height: 4)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = max(0, min(1, value.location.x / geometry.size.width))
                        viewModel.seek(to: ratio * viewModel.duration)
                    }
            )
        }
        .frame(height: 4)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            VStack(spacing: 8) {
                Text("Video wird vorbereitet...")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Streamen & Entschlüsseln")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("Fehler beim Abspielen")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Button {
                dismiss()
            } label: {
                Text("Zurück")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(40)
    }
}

// MARK: - ViewModel

@MainActor
class KGGVideoPlayerViewModel: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var showControls = true
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var error: Error?

    private let encryptedFileURL: URL
    private let decryptionKey: SymmetricKey
    private var resourceLoader: KGGAssetResourceLoader?
    private var timeObserver: Any?

    init(
        encryptedFileURL: URL,
        decryptionKey: SymmetricKey
    ) {
        self.encryptedFileURL = encryptedFileURL
        self.decryptionKey = decryptionKey
        super.init()
    }

    func setupPlayer() {
        do {
            // Decryptor + ResourceLoader
            let decryptor = KGGVideoDecryptor()
            let loader = try decryptor.createResourceLoader(
                encryptedFileURL: encryptedFileURL,
                decryptionKey: decryptionKey
            )
            self.resourceLoader = loader

            // Custom Scheme für AVAsset
            let customURL = URL(string: "kgg://video")!
            let asset = AVURLAsset(url: customURL)
            
            // ResourceLoader registrieren
            asset.resourceLoader.setDelegate(loader, queue: .main)

            // Player setup
            let playerItem = AVPlayerItem(asset: asset)
            let newPlayer = AVPlayer(playerItem: playerItem)

            self.player = newPlayer

            // Duration loader
            Task {
                let duration = try await asset.load(.duration)
                self.duration = CMTimeGetSeconds(duration)
            }

            // Time observer
            let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
            timeObserver = newPlayer.addPeriodicTimeObserver(
                forInterval: interval,
                queue: .main
            ) { [weak self] time in
                Task { @MainActor in
                    self?.currentTime = CMTimeGetSeconds(time)
                }
            }

            // Auto-play
            newPlayer.play()
            
            // Controls Auto-hide
            scheduleControlsHide()

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    func toggleControls() {
        withAnimation {
            showControls.toggle()
        }
        if showControls {
            scheduleControlsHide()
        }
    }

    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player?.pause()
        player = nil
    }

    private func scheduleControlsHide() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            withAnimation {
                self?.showControls = false
            }
        }
    }

    // MARK: - Computed Properties

    var currentTimeText: String {
        formatTime(currentTime)
    }

    var durationText: String {
        formatTime(duration)
    }

    var progressWidth: CGFloat {
        guard duration > 0 else { return 0 }
        let width = 300.0
        return width * (currentTime / duration)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    KGGVideoPlayerView(
        title: "KGG-Video (verschlüsselt)",
        encryptedFileURL: URL(fileURLWithPath: "/tmp/test.agkv"),
        decryptionKey: SymmetricKey(size: .bits256)
    )
}
