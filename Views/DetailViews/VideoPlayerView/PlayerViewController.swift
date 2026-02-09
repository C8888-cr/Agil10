//
//  PlayerViewController.swift
//  Agil10.0
//
//  Created by Christiane Roth on 09.02.26.
//

import SwiftUI
import AVKit
struct PlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false   // <- System-Controls AUS
        vc.videoGravity = .resizeAspect
        return vc
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        uiViewController.showsPlaybackControls = false
    }
}
