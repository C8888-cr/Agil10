//
//  CameraVideoPickerView.swift
//  Agil
//
//  Created by Christiane Roth.
//

import SwiftUI
import AVFoundation
import Combine
import AVKit
import UIKit

// MARK: - Orientation Observer

/// Beobachtet die physische Geräteausrichtung. Wird hier genutzt, um
/// den Aufnahme-Winkel der Kamera zu setzen (damit ein quer gehaltenes
/// Gerät auch ein Querformat-Video aufnimmt) – unabhängig davon, dass
/// die UI selbst auf Hochformat gesperrt ist.
final class OrientationObserver: ObservableObject {

    enum UIOrientation {
        case portrait
        case portraitUpsideDown
        case landscapeLeft
        case landscapeRight
    }

    @Published private(set) var orientation: UIOrientation = .portrait

    private var cancellable: AnyCancellable?

    init() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        cancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in self?.update() }
        update()
    }

    private func update() {
        switch UIDevice.current.orientation {
        case .portrait:            orientation = .portrait
        case .portraitUpsideDown:  orientation = .portraitUpsideDown
        case .landscapeLeft:       orientation = .landscapeLeft
        case .landscapeRight:      orientation = .landscapeRight
        default:
            // .faceUp / .faceDown / .unknown -> letzten Wert behalten.
            break
        }
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

// MARK: - View

struct CameraVideoPickerView: View {
    let onVideoRecorded: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    @StateObject private var camera = CameraManager()
    @StateObject private var orientation = OrientationObserver()

    @State private var mode: Mode = .camera
    @State private var recordedURL: URL?
    @State private var player: AVPlayer?

    enum Mode {
        case camera
        case preview
    }

    var body: some View {
        ZStack {
            // Unterste Ebene: deckt jede Lücke ab, damit kein heller
            // Hintergrund durch die Preview-Ränder scheint.
            Color.black
                .ignoresSafeArea()

            switch mode {
            case .camera:
                cameraView
            case .preview:
                previewView
            }
        }
        .onAppear {
            AppOrientation.lock(.portrait)   // Kamera-UI fest auf Hochformat.
            camera.onVideoRecorded = { url in
                recordedURL = url
                player = AVPlayer(url: url)
                mode = .preview
            }
            camera.startSession()
        }
        .onDisappear {
            AppOrientation.lock(.all)        // Rotation für den Rest der App freigeben.
            camera.stopSession()
            player?.pause()
        }
        .onChange(of: orientation.orientation) { _, _ in
            camera.applyOrientation(orientation.orientation)
        }
    }

    // MARK: - Camera View

    private var cameraView: some View {
        ZStack {
            CameraPreviewContainer(session: camera.session, camera: camera)
                .ignoresSafeArea()

            CameraControlsOverlay(
                isRecording: camera.isRecording,
                recordingDuration: camera.recordingDuration,
                onToggleRecord: {
                    if camera.isRecording { camera.stopRecording() }
                    else { camera.startRecording() }
                },
                onSwitchCamera: { camera.switchCamera() }
            )
        }
    }

    // MARK: - Preview View

    private var previewView: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { configureLoop(for: player) }
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button {
                        discardVideo()
                    } label: {
                        Text("Verwerfen")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                    }
                    .glassEffect(.regular.interactive(), in: .capsule)

                    Button {
                        useVideo()
                    } label: {
                        Text("Benutzen")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                    }
                    .glassEffect(
                        .regular.tint(themeManager.currentTheme.accentColor).interactive(),
                        in: .capsule
                    )

                    Spacer()
                }
                .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Actions

    private func configureLoop(for player: AVPlayer) {
        player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        player.play()
    }

    private func useVideo() {
        if let url = recordedURL {
            onVideoRecorded(url)
        }
        dismiss()
    }

    private func discardVideo() {
        player?.pause()
        if let url = recordedURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordedURL = nil
        player = nil
        mode = .camera
    }
}

// MARK: - Controls Overlay (fester Frame, previewbar)

/// Steuerleiste der Kamera. Liegt fest am unteren Rand, dreht NICHT mit
/// dem Gerät mit (die UI ist ohnehin auf Hochformat gesperrt). Bekommt
/// nur einfache Werte/Closures übergeben → komplett previewbar.
private struct CameraControlsOverlay: View {
    let isRecording: Bool
    let recordingDuration: TimeInterval
    let onToggleRecord: () -> Void
    let onSwitchCamera: () -> Void

    private let barSize = CGSize(width: 280, height: 100)

    var body: some View {
        VStack {
            if isRecording {
                timerLabel.padding(.top, 12)
            }
            Spacer()
            controlBar.padding(.bottom, 28)
        }
    }

    private var timerLabel: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
            Text(Self.format(recordingDuration))
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
    }

    private var controlBar: some View {
        ZStack {
            // Auslöser – mittig, rotationssymmetrisch.
            Button(action: onToggleRecord) {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 78, height: 78)

                    RoundedRectangle(
                        cornerRadius: isRecording ? 8 : 32,
                        style: .continuous
                    )
                    .fill(.red)
                    .frame(width: isRecording ? 32 : 64,
                           height: isRecording ? 32 : 64)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .animation(.spring(response: 0.3, dampingFraction: 0.7),
                           value: isRecording)
            }

            // Kamera wechseln – rechts vom Auslöser.
            HStack {
                Spacer()
                Button(action: onSwitchCamera) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            }
        }
        .frame(width: barSize.width, height: barSize.height)
    }

    static func format(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

// MARK: - Camera Manager

final class CameraManager: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    let session = AVCaptureSession()
    private let output = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    @Published var isRecording = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back
    @Published var recordingDuration: TimeInterval = 0

    var onVideoRecorded: ((URL) -> Void)?
    var currentDevice: AVCaptureDevice?
    var currentRotationAngle: CGFloat = 90

    private var recordingTimer: Timer?
    private var recordingStartDate: Date?
    private var hasConfigured = false

    // MARK: Session

    func startSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.configureAndStart() }
            }
        default:
            break
        }

        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private func configureAndStart() {
        sessionQueue.async {
            guard !self.hasConfigured else {
                if !self.session.isRunning { self.session.startRunning() }
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            self.configureInputs(position: self.currentCameraPosition)

            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }

            self.session.commitConfiguration()
            self.hasConfigured = true
            self.session.startRunning()
        }
    }

    private func configureInputs(position: AVCaptureDevice.Position) {
        session.inputs.forEach { session.removeInput($0) }

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: position),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            return
        }

        currentDevice = videoDevice
        session.addInput(videoInput)

        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
    }

    func switchCamera() {
        guard !isRecording else { return }
        let newPosition: AVCaptureDevice.Position =
            (currentCameraPosition == .back) ? .front : .back

        // @Published nur auf dem Main-Thread ändern …
        DispatchQueue.main.async { self.currentCameraPosition = newPosition }

        // … die Session-Arbeit bleibt auf der sessionQueue.
        sessionQueue.async {
            self.session.beginConfiguration()
            self.configureInputs(position: newPosition)
            self.session.commitConfiguration()
        }
    }

    // MARK: Orientation (Aufnahme-Winkel)

    func applyOrientation(_ orientation: OrientationObserver.UIOrientation) {
        switch orientation {
        case .portrait:           currentRotationAngle = 90
        case .portraitUpsideDown: currentRotationAngle = 270
        case .landscapeLeft:      currentRotationAngle = 0
        case .landscapeRight:     currentRotationAngle = 180
        }
        sessionQueue.async {
            if let connection = self.output.connection(with: .video),
               connection.isVideoRotationAngleSupported(self.currentRotationAngle) {
                connection.videoRotationAngle = self.currentRotationAngle
            }
        }
    }

    // MARK: Recording

    func startRecording() {
        guard !output.isRecording else { return }

        // Kein aktiver Video-Anschluss (Simulator / Session noch nicht fertig)
        // → nicht starten, sonst Crash "No active/enabled connections".
        guard let connection = output.connection(with: .video) else {
            print("⚠️ Keine aktive Video-Verbindung – Aufnahme nicht möglich (Simulator?).")
            return
        }

        if connection.isVideoRotationAngleSupported(currentRotationAngle) {
            connection.videoRotationAngle = currentRotationAngle
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        output.startRecording(to: url, recordingDelegate: self)
        DispatchQueue.main.async {
            self.isRecording = true
            self.startTimer()
        }
    }

    func stopRecording() {
        guard output.isRecording else { return }
        output.stopRecording()
        DispatchQueue.main.async {
            self.isRecording = false
            self.stopTimer()
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.stopTimer()
            guard error == nil else { return }
            self.onVideoRecorded?(outputFileURL)
        }
    }

    // MARK: Timer

    private func startTimer() {
        recordingStartDate = Date()
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let start = self.recordingStartDate else { return }
            self.recordingDuration = Date().timeIntervalSince(start)
        }
    }

    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingStartDate = nil
    }
}

// MARK: - Camera Preview Container

struct CameraPreviewContainer: UIViewRepresentable {
    let session: AVCaptureSession
    let camera: CameraManager

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
        uiView.videoPreviewLayer.videoGravity = .resizeAspectFill
        uiView.updateRotation()
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
            updateRotation()
        }

        /// Dreht das Live-Vorschaubild passend zur Geräteausrichtung,
        /// damit es trotz Hochformat-gesperrter UI aufrecht erscheint.
        func updateRotation() {
            let angle: CGFloat
            switch UIDevice.current.orientation {
            case .landscapeLeft:      angle = 0
            case .landscapeRight:     angle = 180
            case .portraitUpsideDown: angle = 270
            case .portrait:           angle = 90
            default:                  angle = 90
            }

            if let connection = videoPreviewLayer.connection,
               connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        }
    }
}

// MARK: - Previews

#Preview("Controls – Aufnahme läuft") {
    ZStack {
        Color.black.ignoresSafeArea()
        CameraControlsOverlay(
            isRecording: true,
            recordingDuration: 75,
            onToggleRecord: {},
            onSwitchCamera: {}
        )
    }
}

#Preview("Controls – bereit") {
    ZStack {
        Color.black.ignoresSafeArea()
        CameraControlsOverlay(
            isRecording: false,
            recordingDuration: 0,
            onToggleRecord: {},
            onSwitchCamera: {}
        )
    }
}
