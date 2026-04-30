import SwiftUI

struct ExpertModePlayerView: View {
    @StateObject private var viewModel: ExpertModeViewModel
    @Environment(\.dismiss) private var dismiss

    let video: Video
    let videoDuringTraining: VideoDuringTrainingMode
    let onComplete: (() -> Void)?                      // 🆕

    @State private var showWeightPrompt: Bool = false
    @State private var promptWeightText: String = ""
    @State private var showIntroVideo: Bool = true
    @State private var showVideoDuringRest: Bool = false

    init(
        video: Video,
        tempoProtocol: TempoProtocol,
        weightKg: Int?,
        setsOverride: Int? = nil,
        repsOverride: Int? = nil,
        restOverride: Int? = nil,
        lastTrainingTotalKg: Int? = nil,
        videoDuringTraining: VideoDuringTrainingMode = .toggleable,
        scheduleId: UUID? = nil,                       // 🆕
        progressViewModel: ProgressViewModel? = nil,   // 🆕
        session: SessionManager? = nil,                // 🆕
        onComplete: (() -> Void)? = nil                // 🆕
    ) {
        self.video = video
        self.videoDuringTraining = videoDuringTraining
        self.onComplete = onComplete

        let effectiveWeight = weightKg ?? 5
        _viewModel = StateObject(wrappedValue: ExpertModeViewModel(
            videoTitle: video.title,
            tempoProtocol: tempoProtocol,
            weightKg: effectiveWeight,
            lastTrainingTotalKg: lastTrainingTotalKg,
            setsOverride: setsOverride,
            repsOverride: repsOverride,
            restOverride: restOverride,
            scheduleId: scheduleId,                    // 🆕
            progressViewModel: progressViewModel,      // 🆕
            session: session,                          // 🆕
            onComplete: onComplete                     // 🆕
        ))
        _promptWeightText = State(initialValue: "\(effectiveWeight)")
        _showWeightPrompt = State(initialValue: weightKg == nil)
    }
    
    // ... body bleibt fast gleich, nur das Rating-Sheet kommt dazu:
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ExpertModeContent(viewModel: viewModel) {
                    dismiss()
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showIntroVideo {
                    introVideoOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.body.weight(.semibold))
                    }
                }
                ToolbarItem(placement: .principal) { }
            }
            .alert("Wie schwer?", isPresented: $showWeightPrompt) {
                TextField("Gewicht in kg", text: $promptWeightText)
                    .keyboardType(.numberPad)
                Button("OK") {
                    if let weight = Int(promptWeightText), weight > 0 {
                        viewModel.weightKg = weight
                    }
                }
                Button("Abbrechen", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Mit welchem Gewicht trainierst du heute?")
            }
            // 🆕 Rating-Sheet wie im VideoPlayerView
            .sheet(isPresented: $viewModel.showRatingSheet, onDismiss: { dismiss() }) {
                VideoRatingSheet(
                    videoTitle: video.title,
                    onRate: { rating in
                        viewModel.saveRating(rating)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .environment(\.colorScheme, .dark)
        }
    }
    


    // MARK: - Intro-Video Overlay

    @ViewBuilder
    private var introVideoOverlay: some View {
        Color.black
            .ignoresSafeArea()
            .overlay {
                GeometryReader { geo in
                    let screenWidth = geo.size.width
                    let screenHeight = geo.size.height
                    let maxVideoWidth = screenWidth * 0.9
                    let videoAspectRatio: CGFloat = 16/9
                    let videoWidth = min(maxVideoWidth, screenHeight * videoAspectRatio)
                    let videoHeight = videoWidth / videoAspectRatio

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

                        ExpertVideoLoopPlayer(
                            video: video,
                            isPlaying: true
                        )
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

#Preview("ExpertModePlayerView") {
    let video = Video(
        title: "Bizeps-Curls",
        videoFileName: "curls.mov",
        category: .strength,
        bodyRegion: .fullBody,
        equipment: .noEquipment,
        durationSeconds: 60,
        defaultRepetitions: 12,
        defaultPauseSeconds: 60,
        loopDurationSeconds: 60,
        rating: 0
    )
    let protocolModel = TempoProtocol(
        concentricSec: 2,
        holdSec: 0,
        eccentricSec: 3,
        sets: 3,
        reps: 12,
        restBetweenSetsSec: 60,
        subtype: .dynamic
    )

    return ExpertModePlayerView(
        video: video,
        tempoProtocol: protocolModel,
        weightKg: nil,
        lastTrainingTotalKg: 180
    )
}
