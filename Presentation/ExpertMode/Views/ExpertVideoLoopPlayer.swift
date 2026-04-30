//
//  ExpertVideoLoopPlayer.swift
//  Agil10.0
//
//  Created by Christiane Roth on 22.04.26.
//


//
//  ExpertVideoLoopPlayer.swift
//  Agil
//
//  Minimaler Video-Loop-Player für ExpertModePlayerView.
//  Stumm, Loop, ohne Controls — nur visueller Kontext.
//

import SwiftUI
import AVKit

struct ExpertVideoLoopPlayer: View {
    let video: Video
    var isPlaying: Bool = true   // kann später per Setting gesteuert werden
    
    @State private var player: AVPlayer?
    @State private var looper: Any?   // AVPlayerLooper muss referenziert bleiben
    
    var body: some View {
        ZStack {
            Color.black
            
            if let player = player {
                ExpertPlayerViewController(player: player)
                    .disabled(true)
            
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
            looper = nil
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                player?.play()
            } else {
                player?.pause()
            }
        }
    }
    
    private func setupPlayer() {
        let fileService = VideoFileService()
        guard let url = fileService.getVideoURL(for: video.videoFileName) else {
            print("⚠️ ExpertVideoLoopPlayer: Video-URL nicht gefunden: \(video.videoFileName)")
            return
        }
        
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        
        // Loop mit AVPlayerLooper
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        self.player = queuePlayer
        
        if isPlaying {
            queuePlayer.play()
        }
    }
    private struct ExpertPlayerViewController: UIViewControllerRepresentable {
        let player: AVPlayer
        
        func makeUIViewController(context: Context) -> AVPlayerViewController {
            let vc = AVPlayerViewController()
            vc.player = player
            vc.showsPlaybackControls = false
            vc.videoGravity = .resizeAspectFill   // ← FILL statt Fit
            return vc
        }
        
        func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
            uiViewController.player = player
        }
    }
}
