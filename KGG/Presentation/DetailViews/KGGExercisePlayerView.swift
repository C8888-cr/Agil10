//
//  KGGExercisePlayerView.swift
//  Agil
//
//  KGG-Player: Video-Intro + Pill-Player (eigenes KGGExercisePlayerViewModel).
//  Read-only: keine Änderung von Gewicht, Tempo, Reps, Sets.
//  Video-Sichtbarkeit wird von außen (KGGExerciseListView) vorgegeben.
//

import SwiftUI
import AVKit

public struct KGGExercisePlayerView: View {

    @StateObject private var viewModel: KGGExercisePlayerViewModel
    @Environment(\.dismiss) private var dismiss

    let video: Video
    let onComplete: (() -> Void)?

    @State private var showIntroVideo = true

    init(
        exercise: KGGScannedExercise,
        video: Video,
        isVideoVisible: Bool,
        repository: KGGExerciseRepository,
        onComplete: (() -> Void)? = nil
    ) {
        self.video = video
        self.onComplete = onComplete

        _viewModel = StateObject(wrappedValue: KGGExercisePlayerViewModel(
            exercise: exercise,
            video: video,
            isVideoVisible: isVideoVisible,
            repository: repository,
            onComplete: onComplete
        ))
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            KGGPlayerContent(viewModel: viewModel) {
                dismiss()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showIntroVideo {
                introVideoOverlay
            }
        }
        .keepScreenAwake()
        .environment(\.colorScheme, .dark)
        .onAppear {
            Task {
                await viewModel.detectVideoOrientation()
            }
        }
        // Sobald das ViewModel den Abschluss meldet (onComplete-Callback
        // wurde intern schon aufgerufen), schließt der Player sich selbst.
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished {
                dismiss()
            }
        }
    }

    // MARK: - Intro Overlay

    @ViewBuilder
    private var introVideoOverlay: some View {
        Color.black
            .ignoresSafeArea()
            .overlay {
                GeometryReader { _ in
                    VStack(alignment: .center, spacing: 20) {
                        VStack(alignment: .center, spacing: 8) {
                            Text("Einstieg: Video schauen")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Perfekt durchführen lernen")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 20)

                        ExpertVideoLoopPlayer(video: video, isPlaying: true)
                            .aspectRatio(9/16, contentMode: .fit)
                            .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .frame(maxWidth: .infinity)

                        Button("Workout starten") {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showIntroVideo = false
                            }
                            viewModel.onPrimaryButtonTapped()
                        }
                        .font(.headline)
                        .frame(maxWidth: 260)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button("Video überspringen") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showIntroVideo = false
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: showIntroVideo)
    }
}
