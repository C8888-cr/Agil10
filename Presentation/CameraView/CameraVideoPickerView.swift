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

/// Beobachtet die Geräteausrichtung und liefert den Rotationswinkel
/// für das UI. Hält bei .faceUp / .faceDown / .unknown den letzten
/// gültigen Wert, damit die UI beim Hinlegen des Geräts nicht springt.
final class OrientationObserver: ObservableObject {

    /// Vier UI-relevante Ausrichtungen.
    enum UIOrientation {
        case portrait
        case portraitUpsideDown
        case landscapeLeft
        case landscapeRight

        /// Drehung, die das UI gegen die Geräteausrichtung ausführen muss.
        var rotationAngle: Angle {
            switch self {
            case .portrait:           return .degrees(0)
            case .portraitUpsideDown: return .degrees(180)
            case .landscapeLeft:      return .degrees(90)
            case .landscapeRight:     return .degrees(-90)
            }
        }
    }

    @Published private(set) var orientation: UIOrientation = .portrait

    /// Bequemer Zugriff auf den Rotationswinkel.
    var rotationAngle: Angle { orientation.rotationAngle }

    private var cancellable: AnyCancellable?

    init() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        cancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.update()
            }
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

    /// Größe der Control-Bar-Einheit (fix, damit Rotation nie aus dem
    /// Screen läuft). Geräteunabhängig, da rein layout-bezogen.
    private let barSize = CGSize(width: 280, height: 100)

    /// Zusätzlicher Abstand der Bar-Mitte zur Safe-Area-Kante.
    private let barInset: CGFloat = 24

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
            camera.onVideoRecorded = { url in
                recordedURL = url
                player = AVPlayer(url: url)
                mode = .preview
            }
            camera.startSession()
        }
        .onDisappear {
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

                VStack {
                    Spacer()
                    controlBar
                        .padding(.bottom, 28)
                }
            }
        }

    /// Die Control-Bar als eigenständige, fest dimensionierte Einheit.
    private var controlBar: some View {
        ZStack {
            // Auslöser – mittig. Rotationssymmetrisch, muss nicht kippen.
            Button {
                if camera.isRecording {
                    camera.stopRecording()
                } else {
                    camera.startRecording()
                }
            } label: {
                ZStack {
                    // Äußerer weißer Ring – bleibt immer gleich.
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 78, height: 78)

                    // Innen: roter Kreis <-> rotes abgerundetes Quadrat.
                    RoundedRectangle(
                        cornerRadius: camera.isRecording ? 8 : 32,
                        style: .continuous
                    )
                    .fill(.red)
                    .frame(width: camera.isRecording ? 32 : 64,
                           height: camera.isRecording ? 32 : 64)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .animation(.spring(response: 0.3, dampingFraction: 0.7),
                           value: camera.isRecording)
            }

            // Kamera-wechseln – reines Dreh-Symbol, rechts vom Auslöser.
            // Das Symbol kippt mit, damit es immer aufrecht wirkt.
            HStack {
                Spacer()
                Button {
                    camera.switchCamera()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .frame(width: 52, height: 52)
                                            .rotationEffect(orientation.rotationAngle)
                                            .animation(.easeInOut(duration: 0.25),
                                                       value: orientation.orientation)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            }
        }
        .frame(width: barSize.width, height: barSize.height)
    }

    /// Mittelpunkt der Bar je nach Geräteausrichtung. Nutzt die
    /// Safe-Area-Insets des GeometryReaders, damit der Abstand zur
    /// physischen Kante auf jedem iPhone-Modell stimmt.
    private func barPosition(in geo: GeometryProxy) -> CGPoint {
        let size = geo.size
        let safe = geo.safeAreaInsets

        switch orientation.orientation {
        case .portrait:
            return CGPoint(
                x: size.width / 2,
                y: size.height - safe.bottom - barSize.height / 2 - barInset
            )
        case .portraitUpsideDown:
            return CGPoint(
                x: size.width / 2,
                y: safe.top + barSize.height / 2 + barInset
            )
        case .landscapeLeft:
            // Physisch unten = linke Bildschirmkante.
            return CGPoint(
                x: safe.leading + barSize.height / 2 + barInset,
                y: size.height / 2
            )
        case .landscapeRight:
            // Physisch unten = rechte Bildschirmkante.
            return CGPoint(
                x: size.width - safe.trailing - barSize.height / 2 - barInset,
                y: size.height / 2
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

// MARK: - Camera Manager

final class CameraManager: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    let session = AVCaptureSession()
    private let output = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    @Published var isRecording = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back

    var onVideoRecorded: ((URL) -> Void)?
    var currentDevice: AVCaptureDevice?
    var currentRotationAngle: CGFloat = 90

    private var hasConfigured = false

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
        self.session.inputs.forEach { self.session.removeInput($0) }

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              self.session.canAddInput(videoInput) else {
            return
        }

        self.currentDevice = videoDevice
        self.session.addInput(videoInput)

        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           self.session.canAddInput(audioInput) {
            self.session.addInput(audioInput)
        }
    }

    func switchCamera() {
        sessionQueue.async {
            guard !self.isRecording else { return }

            self.currentCameraPosition = (self.currentCameraPosition == .back) ? .front : .back
            self.session.beginConfiguration()
            self.configureInputs(position: self.currentCameraPosition)
            self.session.commitConfiguration()
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func startRecording() {
        guard !output.isRecording else { return }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        if let connection = output.connection(with: .video),
           connection.isVideoRotationAngleSupported(currentRotationAngle) {
            connection.videoRotationAngle = currentRotationAngle
        }

        output.startRecording(to: url, recordingDelegate: self)
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    func stopRecording() {
        guard output.isRecording else { return }
        output.stopRecording()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            guard error == nil else { return }
            self.onVideoRecorded?(outputFileURL)
        }
    }

    func updateRotation(for size: CGSize) {
        let orientation = UIDevice.current.orientation
        switch orientation {
        case .landscapeLeft:
            currentRotationAngle = 0
        case .landscapeRight:
            currentRotationAngle = 180
        case .portraitUpsideDown:
            currentRotationAngle = 270
        case .portrait:
            currentRotationAngle = 90
        default:
            currentRotationAngle = 90
        }

        sessionQueue.async {
            if let connection = self.output.connection(with: .video),
               connection.isVideoRotationAngleSupported(self.currentRotationAngle) {
                connection.videoRotationAngle = self.currentRotationAngle
            }
        }
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
        uiView.updateRotation(camera: camera)
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
            updateRotation(camera: nil)
        }

        func updateRotation(camera: CameraManager?) {
            let orientation = UIDevice.current.orientation
            let angle: CGFloat
            switch orientation {
            case .landscapeLeft:
                angle = 0
            case .landscapeRight:
                angle = 180
            case .portraitUpsideDown:
                angle = 270
            case .portrait:
                angle = 90
            default:
                angle = 90
            }

            if let connection = videoPreviewLayer.connection,
               connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        }
    }
}
