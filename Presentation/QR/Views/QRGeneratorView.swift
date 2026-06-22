// MARK: - Views/QRGenerator/QRGeneratorView.swift

import SwiftUI
import AgilCore

struct QRGeneratorView: View {
    @StateObject private var viewModel = QRGeneratorViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("QR-Behandlungsplan")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Erstelle einen QR-Code für Patientenübungen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // MARK: - Übungsliste
                VStack(alignment: .leading, spacing: 12) {
                    Text("Übungen")
                        .font(.headline)
                    
                    ForEach(viewModel.assignments) { assignment in
                        AssignmentRow(assignment: assignment)
                    }
                }
                
                // MARK: - QR Preview
                if let qrString = viewModel.qrCodeString {
                    VStack(spacing: 16) {
                        QRCodeImage(content: qrString)
                            .frame(width: 200, height: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Text("QR bereit zum Scannen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // MARK: - Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // MARK: - Button
                Button(action: { viewModel.generateQR() }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("QR generieren")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.isLoading)
            }
            .padding()
            .navigationTitle("QR-Generator")
        }
    }
}

// MARK: - Assignment Row
struct AssignmentRow: View {
    let assignment: ExerciseAssignment
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Exercise \(assignment.exerciseId.uuidString.prefix(8))")
                    .fontWeight(.semibold)
                Text("\(assignment.reps) Reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(assignment.weight)) kg")
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - QR Code Image
struct QRCodeImage: View {
    let content: String
    
    var body: some View {
        Image(systemName: "qrcode")
            .font(.system(size: 120))
            .foregroundColor(.blue)
    }
}

#Preview {
    QRGeneratorView()
}
