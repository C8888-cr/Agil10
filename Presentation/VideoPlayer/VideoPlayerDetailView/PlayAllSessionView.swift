import SwiftUI
import SwiftData

struct PlayAllSessionView: View {
    let schedules: [VideoSchedule]
    let session: SessionManager
    let progressVM: ProgressViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var phase: Phase = .playing
    @State private var countdown: Int = 60
    @State private var countdownTimer: Timer?
    
    enum Phase { case playing, countdown, done }
    
    private var currentSchedule: VideoSchedule? {
        guard currentIndex < schedules.count else { return nil }
        return schedules[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch phase {
            case .playing:
                if let schedule = currentSchedule, let video = schedule.video {
                    VideoPlayerView(
                        video: video,
                        scheduleId: schedule.id,
                        progressViewModel: progressVM,
                        session: session,
                        onComplete: {
                            goToNext()
                        }
                    )
                    .environmentObject(progressVM)
                    .id(currentIndex)
                }
                
            case .countdown:
                CountdownBetweenVideosView(
                    countdown: countdown,
                    nextVideoTitle: schedules[safe: currentIndex]?.video?.title ?? ""
                )
                .onAppear { startCountdown() }
                
            case .done:
                AllDoneView { dismiss() }
            }
        }
    }
    
    private func goToNext() {
        countdownTimer?.invalidate()
        currentIndex += 1
        if currentIndex >= schedules.count {
            phase = .done
        } else {
            countdown = 60
            phase = .countdown
        }
    }
    
    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if self.countdown > 0 {
                    self.countdown -= 1
                } else {
                    self.countdownTimer?.invalidate()
                    // ← Delay damit SwiftUI VideoPlayerView komplett neu erstellt
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                    self.phase = .playing
                }
            }
        }
    }
}

// MARK: - Countdown View
struct CountdownBetweenVideosView: View {
    let countdown: Int
    let nextVideoTitle: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Pause")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: CGFloat(countdown) / 60.0)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: countdown)
                
                Text("\(countdown)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            
            VStack(spacing: 8) {
                Text("Nächstes Video")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                Text(nextVideoTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

// MARK: - Done View
struct AllDoneView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("")
                .font(.system(size: 80))
            Text("Training abgeschlossen!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text("Alle Videos wurden abgespielt.")
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Button("Fertig") { onDismiss() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accent)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Safe Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview("Play All – Playing State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: VideoSchedule.self, Video.self,
        configurations: config
    )
    let context = ModelContext(container)
    let sessionManager = SessionManager(
        userRepository: UserRepository(modelContext: context)
    )
    let progressVM = ProgressPreviewHelper.makeProgressVM(context: context)

    let v1 = Video.previewWarmup
    let v2 = Video.previewMobility
    let v3 = Video.previewStrength

    let schedules = [
        VideoSchedule(scheduledDate: .now, orderIndex: 0, video: v1),
        VideoSchedule(scheduledDate: .now, orderIndex: 1, video: v2),
        VideoSchedule(scheduledDate: .now, orderIndex: 2, video: v3),
    ]

    return PlayAllSessionView(
        schedules: schedules,
        session: sessionManager,     // ← statt authService
        progressVM: progressVM
    )
    .modelContainer(container)
}
