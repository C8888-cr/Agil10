//
//  KGGPatientDetailView.swift
//  AgilKGG
//
//  Patient-Detail: QR-Code, Therapie-Info (kompakte Zeile → Detail-Sheet),
//  Warmup (verwaltbar), Übungen (Thumbnails, editierbar, löschbar),
//  Patienten-Historie. Cards mit Schatten.
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
    @State private var showingAddWarmup = false
    @State private var showingHistory = false
    @State private var showingQRCode = false
    @State private var qrCodeImage: UIImage?
    @State private var selectedExercise: KGGExercise?
    @State private var exerciseToDelete: KGGExercise?
    @State private var errorMessage: String?

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
                    therapistInfoRow
                    warmupCard
                    exercisesCard
                    addExerciseButton
                    historyRow
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
        .sheet(isPresented: $showingAddWarmup) {
            KGGAddWarmupSheet(accent: accent) { type, duration, level, seatLevel, speedKmh, weight, notes in
                do {
                    try viewModel.addWarmup(
                        type: type,
                        duration: duration,
                        level: level,
                        speedKmh: speedKmh,
                        seatLevel: seatLevel,
                        weight: weight,
                        notes: notes
                    )
                } catch {
                    errorMessage = "Warmup konnte nicht gespeichert werden: \(error.localizedDescription)"
                }
            }
        }
        .fullScreenCover(isPresented: $showingHistory) {
            KGGPatientHistoryView(
                patientId: viewModel.patient.id,
                patientNumber: viewModel.patient.patientNumber,
                modelContext: modelContext
            )
            .environmentObject(themeManager)
        }
        .fullScreenCover(item: $selectedExercise) { exercise in
            KGGExerciseEditorView(
                exercise: exercise,
                modelContext: modelContext,
                patientId: viewModel.patient.id,
                thumbnailData: viewModel.libraryThumbnail(for: exercise)
            )
            .environmentObject(themeManager)
        }
        .alert("Übung löschen?", isPresented: .constant(exerciseToDelete != nil), presenting: exerciseToDelete) { exercise in
            Button("Löschen", role: .destructive) {
                deleteExercise(exercise)
            }
            Button("Abbrechen", role: .cancel) {
                exerciseToDelete = nil
            }
        } message: { exercise in
            Text("'\(exercise.videoTitle)' wird beim Patienten entfernt. Der Eintrag bleibt in der Historie erhalten.")
        }
        .alert("Fehler", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
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
                    Text("\(viewModel.activeExercises.count) Übungen übertragen")
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

    // MARK: - Therapie-Info (kompakte Zeile → Detail-Sheet)

    private var therapistInfoRow: some View {
        Button {
            showingEditTherapistInfo = true
        } label: {
            HStack(spacing: 16) {
               
                VStack(alignment: .leading, spacing: 4) {
                    Text("Therapie-Info")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(therapistInfoSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if !viewModel.patient.restrictions.isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }

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

    private var therapistInfoSummary: String {
        if viewModel.patient.diagnosis.isEmpty { return "Noch keine Angaben" }
        return viewModel.patient.diagnosis
    }

    // MARK: - Warmup

    private var warmupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Warmup")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    showingAddWarmup = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(accent)
                }
            }

            if viewModel.patient.warmupTemplate.isEmpty {
                Text("Kein Warmup festgelegt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.patient.warmupTemplate.sorted(by: { $0.order < $1.order })) { warmup in
                        warmupRow(warmup)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func warmupRow(_ warmup: KGGWarmup) -> some View {
        HStack(spacing: 12) {

            VStack(alignment: .leading, spacing: 2) {
                         Text(warmup.type)
                             .font(.caption)
                             .fontWeight(.semibold)
                         Text(warmup.displayText)
                             .font(.caption2)
                             .foregroundStyle(.secondary)
                     }
            Spacer()
            Button {
                removeWarmup(warmup)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Übungen

    private var exercisesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Übungen")
                .font(.headline)
                .fontWeight(.semibold)

            if viewModel.activeExercises.isEmpty {
                Text("Keine Übungen zugewiesen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.activeExercises) { exercise in
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
            HStack(spacing: 12) {
                // Video-Thumbnail (Lookup über videoId)
                Group {
                    if let data = viewModel.libraryThumbnail(for: exercise),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Rectangle().fill(Color(.systemGray5))
                            Image(systemName: "video.slash")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.videoTitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("\(exercise.reps)x\(exercise.sets) · \(Int(exercise.weight))kg · Pause \(exercise.pauseBetweenSets)s")
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
        .contextMenu {
            Button(role: .destructive) {
                exerciseToDelete = exercise
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
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

    // MARK: - Historie

    private var historyRow: some View {
        Button {
            showingHistory = true
        } label: {
            HStack(spacing: 16) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Historie")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Alle Änderungen dieses Patienten")
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

    // MARK: - Aktionen

    private func deleteExercise(_ exercise: KGGExercise) {
        do {
            try viewModel.deactivateExercise(exercise)
        } catch {
            errorMessage = "Löschen fehlgeschlagen: \(error.localizedDescription)"
        }
        exerciseToDelete = nil
    }

    private func removeWarmup(_ warmup: KGGWarmup) {
        do {
            try viewModel.removeWarmup(warmup.id)
        } catch {
            errorMessage = "Warmup konnte nicht entfernt werden: \(error.localizedDescription)"
        }
    }

    private func assignExercise(_ exercise: KGGLibraryExercise, reps: Int, sets: Int, weight: Double, pause: Int, tempo: String) {
        do {
            try viewModel.addExercise(
                videoId: exercise.id,
                videoTitle: exercise.title,
                sparte: exercise.gelenk ?? "",
                muskelgruppe: exercise.muskel ?? "",
                equipment: exercise.geraet ?? "",
                reps: reps,
                sets: sets,
                weight: weight,
                pauseBetweenSets: pause,
                tempo: tempo
            )
        } catch {
            errorMessage = "Übung zuweisen fehlgeschlagen: \(error.localizedDescription)"
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
        KGGAssignExerciseSheet(
            modelContext: modelContext,
            praxisId: viewModel.patient.praxisId
        ) { exercise, reps, sets, weight, pause, tempo in
            assignExercise(exercise, reps: reps, sets: sets, weight: weight, pause: pause, tempo: tempo)
        }
        .environmentObject(themeManager)
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
            errorMessage = error.localizedDescription
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
