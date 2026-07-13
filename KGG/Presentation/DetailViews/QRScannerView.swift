//
//  QRScannerView.swift
//  Agil
//
//  QR-Scanner für KGG-Sparte.
//  Nutzt Vision Framework zum Lesen von QR-Codes.
//

import SwiftUI
import AVFoundation
import Vision

public struct QRScannerView: UIViewControllerRepresentable {
    
    @Environment(\.dismiss) var dismiss
    let onQRDetected: (String) -> Void
    
    public init(onQRDetected: @escaping (String) -> Void) {
        self.onQRDetected = onQRDetected
    }
    
    public func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onQRDetected = onQRDetected
        controller.onDismiss = { dismiss() }
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

// MARK: - QRScannerViewController (public for UIViewControllerRepresentable)

public class QRScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var onQRDetected: ((String) -> Void)?
    var onDismiss: (() -> Void)?
    
    private let captureSession = AVCaptureSession()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let queue = DispatchQueue(label: "com.agil.qrscanner")
    private var detectedQRs = Set<String>()
    private var isScanning = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            queue.async { [weak self] in
                self?.captureSession.startRunning()
            }
            isScanning = true
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            queue.async { [weak self] in
                self?.captureSession.stopRunning()
            }
            isScanning = false
        }
    }
    
    deinit {
        captureSession.stopRunning()
        detectedQRs.removeAll()
    }
    
    // MARK: - Setup
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            print("❌ QRScannerViewController: Keine Kamera verfügbar")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: queue)
            
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }
            
            previewLayer.session = captureSession
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            queue.async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            print("❌ QRScannerViewController Setup Fehler: \(error.localizedDescription)")
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    // MARK: - QR Detection (safe)
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("🟥 QRScanner: kein pixelBuffer")
            return
        }
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            if let error = error {
                print("🟥 QRScanner Vision-Fehler: \(error.localizedDescription)")
                return
            }
            
            let results = request.results ?? []
            if results.isEmpty {
                // Nichts gefunden in diesem Frame — bei Dauerlicht ok, aber wenn das
                // NIE etwas findet, sehen wir das jetzt zumindest im Log.
            }
            
            for result in results {
                guard let barcode = result as? VNBarcodeObservation else { continue }
                print("🟩 QRScanner erkannt: symbology=\(barcode.symbology.rawValue), payload=\(barcode.payloadStringValue ?? "nil")")
                
                if barcode.symbology == .qr, let qrString = barcode.payloadStringValue {
                    if (self?.detectedQRs.contains(qrString)) != true {
                        self?.detectedQRs.insert(qrString)
                        
                        DispatchQueue.main.async {
                            self?.onQRDetected?(qrString)
                            self?.closeTapped()
                        }
                    }
                }
            }
        }
        
        request.symbologies = [.qr]
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        do {
            try handler.perform([request])
        } catch {
            print("🟥 QRScanner perform-Fehler: \(error.localizedDescription)")
        }
    }
    
    private func handleQRDetected(_ qrString: String) {
        guard let callback = onQRDetected else { return }
        
        isScanning = false
        captureSession.stopRunning()
        callback(qrString)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.closeTapped()
        }
    }
    
    @objc private func closeTapped() {
        isScanning = false
        if captureSession.isRunning {
            queue.async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
        detectedQRs.removeAll()
        onDismiss?()
    }
}
