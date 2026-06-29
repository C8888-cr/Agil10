//
//  KGGPatientDetailView.swift
//  AgilKGG
//
//  Patient-Detail: Therapist-Info, Übungen, Warmup, QR-Code. Cards mit Schatten.
//

import SwiftUI
import SwiftData
import AgilCore
import CoreImage.CIFilterBuiltins

struct KGGPatientDetailView: View {
    @StateObject private var viewModel: KGGPatientDetailViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    @State private var showingEditTherapistInfo = false
    @State private var showingAddExercise = false
    @State private var showingQRCode = false
    @State private var qrCodeImage: UIImage?
    @State private var selectedExercise: KGGExercise?

    private var accent: Color { themeManager.currentTheme.accentColor }

    init(patient: KGGPatient, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: KGGPatientDetailViewModel(patient: patient, modelContext: modelContext))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    qrCard
                    therapistInfoCard
                    if !viewModel.patient.warmupTemplate.isEmpty {
                        warmupCard
                    }
                    exercisesCard
                    addExerciseButton
                }
                .padding(16)
            }
        }
        .navigationTitle(viewModel.patient.patientNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                KGGLogoMenu()
            }
        }
        .sheet(isPresented: $showingEditTherapistInfo) { editTherapistInfoSheet }
        .sheet(isPresented: $showingAddExercise) { addExerciseSheet }
        .sheet(isPresented: $showingQRCode) { qrCodeSheet }
        .sheet(item: $selectedExercise) { exercise in
            KGGExerciseEditorView(exercise: exercise, modelContext: modelContext, patientId: viewModel.patient.id)
                .environmentObject(themeManager)
        }
    }

    // MARK: - QR Card

    private var qrCard: some View {
        Button {
            generateQRCode()
            showingQRCode = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "qrcode")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text("QR-Code erstellen")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(viewModel.patient.exercises.count) Übungen übertragen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Therapist Info

    private var therapistInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Therapie-Info")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    showingEditTherapistInfo = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(accent)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                if viewModel.patient.diagnosis.isEmpty
                    && viewModel.patient.movementLimitation.isEmpty
                    && viewModel.patient.restrictions.isEmpty
                    && viewModel.patient.therapeutistNotes.isEmpty {
                    Text("Noch keine Angaben")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    if !viewModel.patient.diagnosis.isEmpty {
                        infoRow(label: "Diagnose", value: viewModel.patient.diagnosis)
                    }
                    if !viewModel.patient.movementLimitation.isEmpty {
                        infoRow(label: "Bewegungseinschränkung", value: viewModel.patient.movementLimitation)
                    }
                    if !viewModel.patient.restrictions.isEmpty {
                        infoRow(label: "⚠️ Kontraindikationen", value: viewModel.patient.restrictions, color: .red)
                    }
                    if !viewModel.patient.therapeutistNotes.isEmpty {
                        infoRow(label: "Notizen", value: viewModel.patient.therapeutistNotes)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func infoRow(label: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Warmup

    private var warmupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Warmup")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(viewModel.patient.warmupTemplate) { warmup in
                    HStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(warmup.type)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("\(warmup.duration) Min · \(warmup.intensity)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Exercises

    private var exercisesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Übungen")
                .font(.headline)
                .fontWeight(.semibold)

            if viewModel.patient.exercises.isEmpty {
                Text("Keine Übungen zugewiesen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.patient.exercises) { exercise in
                        exerciseRow(exercise)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func exerciseRow(_ exercise: KGGExercise) -> some View {
        Button {
            selectedExercise = exercise
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.videoTitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("\(exercise.reps)x\(exercise.sets) · \(Int(exercise.weight))kg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "pencil.circle.fill")
                    .foregroundStyle(accent)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var addExerciseButton: some View {
        Button {
            showingAddExercise = true
        } label: {
            Label("Übung hinzufügen", systemImage: "plus.circle.fill")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(accent)
                .cornerRadius(12)
        }
    }

    // MARK: - Sheets

    private var editTherapistInfoSheet: some View {
        NavigationStack {
            Form {
                Section("Diagnose") {
                    TextField("z.B. Rotatorenmanschetten-Teilriss", text: $viewModel.patient.diagnosis)
                }
                Section("Bewegungseinschränkung") {
                    TextField("z.B. Schulterflexion auf 110° begrenzt", text: $viewModel.patient.movementLimitation)
                }
                Section("⚠️ Kontraindikationen") {
                    TextField("z.B. Keine Abduktion über 90°", text: $viewModel.patient.restrictions)
                }
                Section("Notizen") {
                    TextEditor(text: $viewModel.patient.therapeutistNotes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Therapie-Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        try? modelContext.save()
                        showingEditTherapistInfo = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var addExerciseSheet: some View {
        NavigationStack {
            VStack {
                Text("Übungsauswahl folgt")
                    .foregroundStyle(.secondary)
                    .padding()
                Spacer()
            }
            .navigationTitle("Neue Übung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { showingAddExercise = false }
                }
            }
        }
    }

    private var qrCodeSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = qrCodeImage {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)

                    Text(viewModel.patient.patientNumber)
                        .font(.headline)
                    Text("Zum Übertragen vom Patienten scannen lassen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    ProgressView()
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle("QR-Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { showingQRCode = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - QR Generation

    private func generateQRCode() {
        do {
            _ = try viewModel.generateQRCode()
            let qrString = try viewModel.encodeQRContent()
            qrCodeImage = makeQRImage(from: qrString)
        } catch {
            print("QR-Fehler: \(error)")
        }
    }

    private func makeQRImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
