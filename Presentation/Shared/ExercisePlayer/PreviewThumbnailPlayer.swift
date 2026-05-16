//
//  PreviewThumbnailPlayer.swift
//  Agil10.0
//
//  Created by Christiane Roth on 16.05.26.
//


import SwiftUI

struct PreviewThumbnailPlayer: View {
    let video: Video
    let isPlaying: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            if isPlaying {
                // Spielt → echter Loop-Player
                ExpertVideoLoopPlayer(video: video, isPlaying: true)
            } else {
                // Pausiert → statisches Thumbnail
                thumbnailImage
            }
            
            // Play/Pause Overlay
            playOverlay
        }
        .contentShape(Rectangle())   // ganzer Bereich tap-fähig
        .onTapGesture {
            onTap()
        }
    }
    
    private var thumbnailImage: some View {
        Group {
            if let thumbnailFileName = video.thumbnailFileName,
               let thumbnail = ThumbnailGeneratorService.shared.loadThumbnail(fileName: thumbnailFileName) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(uiImage: ThumbnailGeneratorService.shared.getThumbnailOrPlaceholder(fileName: nil))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
    }
    
    private var playOverlay: some View {
        // Dezenter halbtransparenter Kreis mit Play/Pause-Icon
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(x: isPlaying ? 0 : 1.5)  // play-icon optisch zentrieren
            )
            .shadow(color: .black.opacity(0.3), radius: 4)
            .opacity(isPlaying ? 0.6 : 0.85)   // wenn spielt, dezenter
    }
}