//
//  VideoPlayerView.swift
//  Agil
//
//  Created by Christiane Roth on 09.12.25.
//
/*

import SwiftUI
import AVKit
struct VideoPlayerView: View {
    @StateObject private var viewModel: VideoPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var progressVM: ProgressViewModel  // ← EnvironmentObject!

    let video: Video
    let scheduleId: UUID?  // ← NEU! Schedule ID
    let progressViewModel: ProgressViewModel?  // ← DEIN ViewModel!
    
    init(video: Video, scheduleId: UUID? = nil, progressViewModel: ProgressViewModel? = nil) {
           self.video = video
        
            self.scheduleId = scheduleId  // ← Schedule ID!
           self.progressViewModel = progressViewModel
           _viewModel = StateObject(wrappedValue: VideoPlayerViewModel(
               video: video,
               scheduleId: scheduleId,  // ← An ViewModel!
               progressViewModel: progressViewModel
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
    }
    
    // MARK: - Player Content
    
    private var playerContentView: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player
                if let player = viewModel.playerService.player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.toggleControls()
                        }
                }
                
                // Gradient Overlays (oben & unten)
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
                    // Top Bar
                    if viewModel.showControls {
                        topBar
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // Center - Play/Pause Button
                    centerControls
                    
                    Spacer()
                    
                    // Bottom Controls
                    if viewModel.showControls {
                        bottomControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
                
                // Training Overlay
                if viewModel.settings.mode == .training,
                   let progress = viewModel.trainingProgress {
                    TrainingOverlayView(progress: progress)
                }
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(alignment: .top, spacing: 16) {
            // Close Button
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
            
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack(spacing: 12) {
                    Label(video.category.rawValue, systemImage: video.category.icon)
                    Label(video.bodyRegion.rawValue, systemImage: video.bodyRegion.icon)
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Mode Menu
            modeMenu
        }
        .padding(.top, 8)
    }
    
    private var modeMenu: some View {
        Menu {
            Picker("Wiedergabe-Modus", selection: $viewModel.settings.mode) {
                ForEach(PlaybackMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .onChange(of: viewModel.settings.mode) { _, newMode in
                viewModel.setMode(newMode)
            }
        } label: {
            Image(systemName: viewModel.settings.mode.icon)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    // MARK: - Center Controls
    
    private var centerControls: some View {
        HStack(spacing: 60) {
            // Backward 10s
            Button {
                viewModel.seekBackward()
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
            
            // Play/Pause
            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
            }
            
            // Forward 10s
            Button {
                viewModel.seekForward()
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
        }
        .opacity(viewModel.showControls ? 1 : 0)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // ✅ VIDEO PROGRESS LEISTE (0:36 / 4:00)
                   HStack {
                       Text(viewModel.formattedCurrentTime)  // 0:36
                       Spacer()
                       Text(viewModel.formattedDuration)     // 4:00
                   }
                   .font(.caption)
                   .foregroundStyle(.white)
                   
            // Progress Bar
            progressBar
            // Training Counter ÜBER Videozeit (1/5)
                   if let progress = viewModel.trainingProgress {
                       Text("\(progress.currentRepetition)/\(progress.totalRepetitions)")
                           .font(.title2)
                           .fontWeight(.bold)
                           .foregroundStyle(.white)
                       Spacer()
                                  if progress.isInPause {
                                      Text("Pause: \(progress.remainingPauseSeconds)s")
                                          .font(.title3)
                                  }
                   }
            // Control Buttons
            HStack(spacing: 20) {
                // Restart
                Button {
                    viewModel.restart()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                // Speed
                speedMenu
                
                Spacer()
                
                // Time Display
                HStack(spacing: 4) {
                    Text(viewModel.formattedCurrentTime)
                    Text("/")
                        .foregroundStyle(.white.opacity(0.6))
                    Text(viewModel.formattedDuration)
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .monospacedDigit()
                
                Spacer()
                
                // Volume/Mute
                Button {
                    viewModel.toggleMute()
                } label: {
                    Image(systemName: viewModel.settings.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                // Fullscreen
                Button {
                    withAnimation {
                        viewModel.isFullscreen.toggle()
                    }
                } label: {
                    Image(systemName: viewModel.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            let safeWidth = max(100, geometry.size.width)
            let duration = max(0.1, viewModel.playerService.progress.duration)
            let bufferedRatio = min(1.0, max(0.0, viewModel.playerService.progress.bufferedTime / duration))
            let progressRatio = min(1.0, max(0.0, viewModel.playerService.progress.progress))
            
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                
                // Buffered
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(
                        width: safeWidth * bufferedRatio,
                        height: 4
                    )
                
                // Progress
                Capsule()
                    .fill(Color.white)
                    .frame(
                        width: safeWidth * progressRatio,
                        height: 4
                    )
            }
            .frame(width: safeWidth, height: 4)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let seekRatio = max(0, min(1, value.location.x / safeWidth))
                        let newTime = seekRatio * duration
                        viewModel.seek(to: newTime)
                    }
            )
        }
        .frame(height: 20)
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
// MARK: - Preview
#Preview("Video Player - Normal") {
    NavigationStack {
        VideoPlayerView(
            video: Video(
                title: "Schulter Mobilisation",
                videoFileName: "shoulder_mobility.mp4",
                category: .mobility,
                bodyRegion: .cervicalSpine,
                equipment: .noEquipment,
                durationSeconds: 420,
                fileSizeBytes: 15_000_000,
                defaultRepetitions: 1,
                defaultPauseSeconds: 30,
                loopDurationSeconds: 420,
                rating: 3
            )
        )
    }
}
#Preview("Video Player - Training") {
    NavigationStack {
        VideoPlayerView(
            video: Video(
                title: "Krafttraining Oberkörper",
                videoFileName: "strength_upper.mp4",
                category: .strength,
                bodyRegion: .arms,
                equipment: .weights,
                durationSeconds: 300,
                fileSizeBytes: 25_000_000,
                defaultRepetitions: 3,
                defaultPauseSeconds: 60,
                loopDurationSeconds: 300, rating: 5
            )
        )
    }
}
#Preview("Video Player - Stretching") {
    NavigationStack {
        VideoPlayerView(
            video: Video(
                title: "Rücken Dehnung",
                videoFileName: "back_stretch.mp4",
                category: .stretching,
                bodyRegion: .lumbarSpine,
                equipment: .bodyweight,
                durationSeconds: 240,
                fileSizeBytes: 10_000_000,
                defaultRepetitions: 2,
                defaultPauseSeconds: 45,
                loopDurationSeconds: 240,
                rating: 4
            )
        )
    }
}
#Preview("Video Player - Mock UI") {
    // Reine UI Preview ohne echtes Video
    NavigationStack {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button {} label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Schulter Mobilisation")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 12) {
                            Label("Mobilisation", systemImage: "figure.flexibility")
                            Label("HWS", systemImage: "figure.stand")
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button {} label: {
                        Image(systemName: "figure.flexibility")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.6), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Spacer()
                
                // Center - Video Mock
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "95E1D3").opacity(0.5),
                                    Color(hex: "4ECDC4").opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 40) {
                        // Center Controls
                        HStack(spacing: 60) {
                            Button {} label: {
                                Image(systemName: "gobackward.10")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white)
                            }
                            
                            Button {} label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(.white)
                            }
                            
                            Button {} label: {
                                Image(systemName: "goforward.10")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        Text("Mock Video Player Preview")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Bottom Controls
                VStack(spacing: 16) {
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(Color.white)
                                .frame(
                                    width: geometry.size.width * 0.35,
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 20)
                    
                    // Control Buttons
                    HStack(spacing: 20) {
                        Button {} label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                        
                        Text("1.0x")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("2:30")
                            Text("/")
                                .foregroundStyle(.white.opacity(0.6))
                            Text("7:00")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        
                        Spacer()
                        
                        Button {} label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                        
                        Button {} label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .statusBarHidden(true)
    }
}
// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
*/

//
//  VideoPlayerView.swift
//  Agil
//
//  Created by Christiane Roth on 09.12.25.
//
import SwiftUI
import AVKit
struct VideoPlayerView: View {
    @StateObject private var viewModel: VideoPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var progressVM: ProgressViewModel
    let video: Video
    let scheduleId: UUID?
    let progressViewModel: ProgressViewModel?
    
    init(video: Video, scheduleId: UUID? = nil, progressViewModel: ProgressViewModel? = nil) {
        self.video = video
        self.scheduleId = scheduleId
        self.progressViewModel = progressViewModel
        _viewModel = StateObject(wrappedValue: VideoPlayerViewModel(
            video: video,
            scheduleId: scheduleId,
            progressViewModel: progressViewModel
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
    }
    
    // MARK: - Player Content
    
    private var playerContentView: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player
                if let player = viewModel.playerService.player {
                    VideoPlayer(player: player)
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
                    if viewModel.showControls {
                        topBar
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // ✅ Training Progress ODER Center Controls
                    if let progress = viewModel.trainingProgress, viewModel.settings.mode == .training {
                        trainingCenterOverlay(progress: progress)
                    } else {
                        centerControls
                    }
                    
                    Spacer()
                    
                    if viewModel.showControls {
                        bottomControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(alignment: .top, spacing: 16) {
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack(spacing: 12) {
                    Label(video.category.rawValue, systemImage: video.category.icon)
                    Label(video.bodyRegion.rawValue, systemImage: video.bodyRegion.icon)
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            modeMenu
        }
        .padding(.top, 8)
    }
    
    private var modeMenu: some View {
        Menu {
            Picker("Wiedergabe-Modus", selection: $viewModel.settings.mode) {
                ForEach(PlaybackMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .onChange(of: viewModel.settings.mode) { _, newMode in
                viewModel.setMode(newMode)
            }
        } label: {
            Image(systemName: viewModel.settings.mode.icon)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    // MARK: - ✅ Training Center Overlay (NEU!)
    
    private func trainingCenterOverlay(progress: TrainingProgress) -> some View {
        VStack(spacing: 20) {
            // Loop Counter
            Text("\(progress.currentRepetition)/\(progress.totalRepetitions)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 10)
            
            // Pause Countdown
            if progress.isInPause {
                VStack(spacing: 8) {
                    Text("PAUSE")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("\(progress.remainingPauseSeconds)s")
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.6))
                )
            } else {
                // Video läuft
                Text("VIDEO LÄUFT")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Center Controls
    
    private var centerControls: some View {
        HStack(spacing: 60) {
            Button {
                viewModel.seekBackward()
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
            
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
            }
        }
        .opacity(viewModel.showControls ? 1 : 0)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            // ✅ Progress Bar
            progressBar
            
            // ✅ Control Buttons Row
            HStack(spacing: 20) {
                // Restart
                Button {
                    viewModel.restart()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                // Speed
                speedMenu
                
                Spacer()
                
                // ✅ EINE Zeitanzeige (Current / Total)
                HStack(spacing: 4) {
                    Text(viewModel.formattedCurrentTime)
                    Text("/")
                        .foregroundStyle(.white.opacity(0.6))
                    Text(viewModel.formattedDuration)
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .monospacedDigit()
                
                Spacer()
                
                // Volume/Mute
                Button {
                    viewModel.toggleMute()
                } label: {
                    Image(systemName: viewModel.settings.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                // Fullscreen
                Button {
                    withAnimation {
                        viewModel.isFullscreen.toggle()
                    }
                } label: {
                    Image(systemName: viewModel.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            let safeWidth = max(100, geometry.size.width)
            let duration = max(0.1, viewModel.playerService.progress.duration)
            let bufferedRatio = min(1.0, max(0.0, viewModel.playerService.progress.bufferedTime / duration))
            let progressRatio = min(1.0, max(0.0, viewModel.playerService.progress.progress))
            
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                
                // Buffered
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: safeWidth * bufferedRatio, height: 4)
                
                // Progress
                Capsule()
                    .fill(Color.white)
                    .frame(width: safeWidth * progressRatio, height: 4)
            }
            .frame(width: safeWidth, height: 4)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let seekRatio = max(0, min(1, value.location.x / safeWidth))
                        let newTime = seekRatio * duration
                        viewModel.seek(to: newTime)
                    }
            )
        }
        .frame(height: 20)
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

