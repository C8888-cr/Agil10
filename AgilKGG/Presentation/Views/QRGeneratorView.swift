//
//  QRGeneratorView.swift
//  AgilKGG
//
//  Generiert QR-Code aus aktueller Patient-Zuordnung.
//  Zeigt QR an, ermöglicht Teilen/Drucken.
//

import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins
import AgilCore

struct QRGeneratorView: View {
    @EnvironmentObject var viewModel: KGGTherapistViewModel
    
    @State private var qrCodeImage: UIImage?
    @State private var showingShareSheet = false
    @State private var showingPrintOptions = false
    @State private var errorAlert: QRAlertError?
    
    private let context = CIContext()
    private let qrFilter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    if let patient = viewModel.selectedPatient {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("QR-Code für \(patient.patientNumber)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(patient.currentAssignments.count) Übungen zugewiesen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    
                    // QR-Code Anzeige
                    VStack(spacing: 16) {
                        if let image = qrCodeImage {
                            qrCodeDisplay(image)
                        } else if viewModel.selectedPatient?.currentAssignments.isEmpty ?? true {
                            noAssignmentsState
                        } else {
                            loadingState
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    if qrCodeImage != nil {
                        actionButtons
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            generateQRCode()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSNotification.Name("PatientAssignmentsChanged")),
            perform: { _ in
                generateQRCode()
            }
        )
        .alert("Fehler", isPresented: .constant(errorAlert != nil), presenting: errorAlert) { error in
            Button("OK") { errorAlert = nil }
        } message: { error in
            Text(error.message)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = qrCodeImage {
                ShareSheet(image: image)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func qrCodeDisplay(_ image: UIImage) -> some View {
        VStack(spacing: 12) {
            // QR-Code Bild
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 4)
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("Bereit zum Scannen")
                        .font(.caption)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                
                Text("Der Patient kann diesen QR-Code mit der Agil-App scannen, um die Übungen auf sein Handy zu laden.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var noAssignmentsState: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                Text("Keine Übungen zugewiesen")
                    .font(.headline)
                
                Text("Weisen Sie mindestens eine Übung zu, um einen QR-Code zu generieren")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentColor)
            
            Text("QR-Code wird generiert...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Teilen-Button
                Button {
                    showingShareSheet = true
                } label: {
                    Label("Teilen", systemImage: "square.and.arrow.up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
                
                // Drucken-Button
                Button {
                    showingPrintOptions = true
                } label: {
                    Label("Drucken", systemImage: "printer")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
            }
            
            // Neu generieren
            Button {
                generateQRCode()
            } label: {
                Label("Neu generieren", systemImage: "arrow.clockwise")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - QR Generation
    
    private func generateQRCode() {
        guard let patient = viewModel.selectedPatient else { return }
        
        do {
            let payload = try viewModel.generateQRForPatient(patient)
            let qrString = try viewModel.encodeQRContent()
            
            // QR-Code generieren
            if let image = generateQRImage(from: qrString) {
                withAnimation {
                    self.qrCodeImage = image
                }
            }
        } catch {
            errorAlert = QRAlertError(message: "QR-Code konnte nicht generiert werden: \(error.localizedDescription)")
        }
    }
    
    private func generateQRImage(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let qrImage = qrFilter.outputImage else { return nil }
        
        // Skalieren für bessere Qualität
        let scale = 10.0
        let scaledImage = qrImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityVC.excludedActivityTypes = [.saveToCameraRoll, .addToReadingList]
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Helper Types

struct QRAlertError: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KGGPatient.self, configurations: config)
    let viewModel = KGGTherapistViewModel(modelContext: container.mainContext)
    
    QRGeneratorView()
        .environmentObject(viewModel)
        .environment(\.modelContext, container.mainContext)
}
