//
//  VideoPlayerView 2.swift
//  Agil10.0
//
//  Created by Christiane Roth on 09.02.26.
//


import SwiftUI
import AVKit
import SwiftData


struct VideoPlayerView: View {
    
    @StateObject private var viewModel: VideoPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var progressVM: ProgressViewModel
    
    let video: Video
    let scheduleId: UUID?
    let progressViewModel: ProgressViewModel?
    let onComplete: (() -> Void)?
    
    init(video: Video,
         scheduleId: UUID? = nil,
         progressViewModel: ProgressViewModel? = nil,
         session: SessionManager,
         onComplete: (() -> Void)? = nil
    ) {
        self.video = video
        self.scheduleId = scheduleId
        self.onComplete = onComplete
        self.progressViewModel = progressViewModel
        _viewModel = StateObject(wrappedValue: VideoPlayerViewModel(
            video: video,
            scheduleId: scheduleId,
            progressViewModel: progressViewModel,
            session: session,
            onComplete: onComplete
        ))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else {
                playerContentView
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(viewModel.isFullscreen)
        .onAppear {
            viewModel.loadVideo()
            viewModel.setDismissAction {
                dismiss()
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Unbekannter Fehler")
        }
        .sheet(isPresented: $viewModel.showRatingSheet) {
                   VideoRatingSheet(
                       videoTitle: video.title,
                       onRate: { rating in
                           viewModel.saveRating(rating)
                       }
                   )
                   .presentationDetents([.medium, .large])
                   .presentationDragIndicator(.visible)
               }
    }
    
    // MARK: - Player Content
    
    private var playerContentView: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player
                if let player = viewModel.playerService.player {
                    PlayerViewController(player: player)
                        .ignoresSafeArea()
                   
                        .onTapGesture {
                            viewModel.toggleControls()
                        }
                }
                
                // Gradient Overlays
                if viewModel.showControls {
                    VStack(spacing: 0) {
                        topGradient
                        Spacer()
                        bottomGradient
                    }
                    .ignoresSafeArea()
                }
                
                // Controls Layer
                VStack(spacing: 0) {
                    // ✅ TOP: X (links) + Speed (rechts)
                    if viewModel.showControls {
                        topBar
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // ✅ CENTER: Play/Pause Button
               //     centerControls
                    
                    Spacer()
                    
                    // ✅ BOTTOM: Timeline + Blauer Balken + Mute Button
                    if viewModel.showControls {
                        bottomControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - TOP BAR (X + Speed)
    
    private var topBar: some View {
        HStack(spacing: 16) {
            // ✅ X Button (links)
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
            
            Spacer()
            
            
            Button {
                       viewModel.toggleMute()
                   } label: {
                       Image(systemName: viewModel.settings.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                           .font(.title3)
                           .foregroundStyle(.white)
                           .frame(width: 44, height: 44)
                           .background(Color.black.opacity(0.3))
                           .clipShape(Circle())
                   }
               
        
        
            // ✅ Speed Menu (rechts)
       //     speedMenu
        }
        .padding(.top, 8)
    }
    
    // MARK: - CENTER CONTROLS (Play/Pause)
    

    
    // MARK: - BOTTOM CONTROLS (Blauer Balken + Timeline + Mute)
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // ✅ Nur Pause-Anzeige, kein blauer Balken mehr
            if let progress = viewModel.trainingProgress,
               viewModel.settings.mode == .training,
               progress.isInPause {
                
                VStack(spacing: 8) {
                    Text("PAUSE")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("\(progress.remainingPauseSeconds)s")
                        .font(.system(size: 96, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    
                    Text("Nächste Runde \(progress.currentRepetition + 1)/\(progress.totalRepetitions)")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.6))
                )
            }
            
            // ✅ Timeline (UNTEN)
            progressBar
            
            // ✅ Mute Button (unten links, klein)
        /*    HStack {
                Button {
                    viewModel.toggleMute()
                } label: {
                    Image(systemName: viewModel.settings.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Spacer()
            }*/
        }
        .padding(.bottom, 8)
    }
    /*
    // MARK: - CENTER CONTROLS (Play/Pause - NUR wenn Tap!)
    private var centerControls: some View {
        HStack(spacing: 60) {
            Button {
                viewModel.seekBackward()
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .opacity(viewModel.showControls ? 1 : 0)
            }
            .disabled(!viewModel.showControls)
            
            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
            }
            
            Button {
                viewModel.seekForward()
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .opacity(viewModel.showControls ? 1 : 0)
            }
            .disabled(!viewModel.showControls)
        }
        .opacity(viewModel.showControls ? 1 : 0)
    }
    */
    // MARK: - Progress Bar
 
    // In VideoPlayerView.swift
    private var progressBar: some View {
        GeometryReader { geometry in
            let safeWidth = max(100, geometry.size.width)
            
            // ✅ LOOP-BASIERTE Werte (verwendet totalPlayTime!)
            let loopDuration = viewModel.currentLoopDuration
            let timeInLoop = viewModel.totalPlayTime.truncatingRemainder(dividingBy: max(0.1, loopDuration))
            let progressRatio = min(1.0, max(0.0, timeInLoop / max(0.1, loopDuration)))
            
            VStack(spacing: 8) {
                // ✅ Zeit-Anzeige
                HStack {
                    Text(viewModel.loopTimeText)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                        .monospacedDigit()
                    
                    Spacer()
                    
                    // ✅ Loop-Indikator (nur im Training Mode)
                    if viewModel.settings.mode == .training,
                       let progress = viewModel.trainingProgress {
                        Text("Wiederholung \(progress.currentRepetition)/\(progress.totalRepetitions)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                
                // ✅ Progress Bar
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress (Loop-basiert!)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: safeWidth * progressRatio, height: 4)
                }
                .frame(width: safeWidth, height: 4)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let seekRatio = max(0, min(1, value.location.x / safeWidth))
                            
                            // ✅ Seek innerhalb des aktuellen Loops
                            let currentLoopIndex = Int(viewModel.totalPlayTime / loopDuration)
                            let loopStartTime = TimeInterval(currentLoopIndex) * loopDuration
                            let newTime = loopStartTime + (seekRatio * loopDuration)
                            
                            // ✅ WICHTIG: totalPlayTime manuell setzen!
                            viewModel.totalPlayTime = newTime
                            
                            // Dann Player seek
                            let videoTime = newTime.truncatingRemainder(dividingBy: max(0.1, Double(viewModel.video.durationSeconds)))
                            viewModel.seek(to: videoTime)
                        }
                )
            }
        }
        .frame(height: 40)  // ✅ Mehr Platz für Text
    }
 
    // MARK: - Speed Menu
    
    private var speedMenu: some View {
        Menu {
            Picker("Geschwindigkeit", selection: $viewModel.settings.speed) {
                ForEach(PlaybackSpeed.allCases) { speed in
                    Text(speed.displayText).tag(speed)
                }
            }
            .onChange(of: viewModel.settings.speed) { _, newSpeed in
                viewModel.setSpeed(newSpeed)
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.settings.speed.displayText)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Gradients
    
    private var topGradient: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.6),
                Color.black.opacity(0.3),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 120)
    }
    
    private var bottomGradient: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.black.opacity(0.3),
                Color.black.opacity(0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 150)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Video wird geladen...")
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}
#Preview("VideoPlayerView - Training Mode") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Video.self,
        configurations: config
    )
    let context = ModelContext(container)
    let sessionManager = SessionManager(
        userRepository: UserRepository(modelContext: context)
    )
    let progressVM = ProgressPreviewHelper.makeProgressVM(context: context)
    
    let mockVideo = Video(
        title: "Schulter Mobilisation",
        videoFileName: "shoulder.mov",
        category: .mobility,
        bodyRegion: .cervicalSpine,
        equipment: .noEquipment,
        durationSeconds: 120,
        defaultRepetitions: 3,
        defaultPauseSeconds: 30,
        loopDurationSeconds: 120,
        rating: 4
    )
    
    return VideoPlayerView(
        video: mockVideo,
        scheduleId: UUID(),
        session: sessionManager
    )
    .environmentObject(progressVM)
}
