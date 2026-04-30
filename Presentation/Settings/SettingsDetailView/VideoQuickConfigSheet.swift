//
//  VideoQuickConfigSheet.swift
//  Agil10.0
//

import SwiftUI
import SwiftData

struct VideoQuickConfigSheet: View {
    let video: Video
    let activeMode: String

    // Bestehende States
    @State private var repetitions: Int
    @State private var loopDurationSeconds: Int
    @State private var pauseSeconds: Int
    @State private var selectedPlanMode: String
    @State private var weightKgText: String

    // 🆕 Expertenmodus-States
    @State private var sets: Int
    @State private var repsPerSet: Int

    let onAdd: (Int, Int, Int, String, Int?, Int?, Int?) -> Void
    //          reps, loop,  pause, planMode, weight, sets, repsPerSet
    let onCancel: () -> Void

    init(
        video: Video,
        activeMode: String = "single",
        initialRepetitions: Int? = nil,
        initialLoopDuration: Int? = nil,
        initialPause: Int? = nil,
        initialWeightKg: Int? = nil,
        initialSets: Int? = nil,
        initialRepsPerSet: Int? = nil,
        onAdd: @escaping (Int, Int, Int, String, Int?, Int?, Int?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.video = video
        self.activeMode = activeMode
        self.onAdd = onAdd
        self.onCancel = onCancel

        _repetitions = State(initialValue: initialRepetitions ?? video.defaultRepetitions)
        _loopDurationSeconds = State(initialValue: max(10, initialLoopDuration ?? video.loopDurationSeconds))
        _pauseSeconds = State(initialValue: initialPause ?? video.defaultPauseSeconds)
        _selectedPlanMode = State(initialValue: activeMode)
        _weightKgText = State(initialValue: initialWeightKg.map { "\($0)" } ?? "")

        // 🆕 Expert-Defaults: erst Override aus Schedule, dann aus tempoProtocol, dann sinnvolle Defaults
        let defaultSets = initialSets ?? video.tempoProtocol?.sets ?? 3
        let defaultReps = initialRepsPerSet ?? video.tempoProtocol?.reps ?? 12
        _sets = State(initialValue: defaultSets.clamped(to: 1...6))
        _repsPerSet = State(initialValue: defaultReps.clamped(to: 8...15))
    }

    // MARK: - Mode Detection

    /// Expertenmodus = Kraft + dynamisches Tempo-Protokoll
    private var isExpertDynamicMode: Bool {
        video.category == .strength
        && video.tempoProtocol?.subtype == .dynamic
    }

    /// Gewicht-Sektion bei Kraft mit jeglichem Tempo-Protokoll
    private var showsWeightSection: Bool {
        video.category == .strength && video.tempoProtocol != nil
    }

    private var parsedWeight: Int? {
        let trimmed = weightKgText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Int(trimmed)
    }

    // MARK: - Total Duration

    /// Gesamtdauer je nach Modus
    private var totalSeconds: Int {
        if isExpertDynamicMode, let tempo = video.tempoProtocol {
            // Expertenmodus: sets × (reps × cycleDur) + (sets-1) × pause
            let cycle = tempo.cycleDurationSec
            let workPerSet = repsPerSet * cycle
            let totalWork = workPerSet * sets
            let totalRest = pauseSeconds * max(0, sets - 1)
            return totalWork + totalRest
        } else {
            // Standard: loops × loopDuration + (loops-1) × pause
            return (loopDurationSeconds * repetitions) + (pauseSeconds * max(0, repetitions - 1))
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                videoInfoSection

                if showsWeightSection {
                    weightSection
                }

                if isExpertDynamicMode {
                    expertSetsRepsSection
                    expertPauseSection
                } else {
                    standardRepetitionsSection
                    standardLoopDurationSection
                    standardPauseSection
                }

                if activeMode != "single" {
                    planModeSection
                }
            }
            .navigationTitle("Video konfigurieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hinzufügen") {
                        let setsValue = isExpertDynamicMode ? sets : nil
                        let repsValue = isExpertDynamicMode ? repsPerSet : nil
                        onAdd(
                            repetitions,
                            loopDurationSeconds,
                            pauseSeconds,
                            selectedPlanMode,
                            parsedWeight,
                            setsValue,
                            repsValue
                        )
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.accent)
                }
            }
        }
    }

    // MARK: - Sections

    private var videoInfoSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title).font(.headline)
                    Text(video.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Gesamt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(totalSeconds))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accent)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var weightSection: some View {
        Section {
            HStack {
                Label("Gewicht", systemImage: "scalemass")
                Spacer()
                TextField("—", text: $weightKgText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
                Text("kg").foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Gewicht")
        } footer: {
            Text("Optional — kann auch später beim Training eingegeben werden.")
        }
    }

    // 🆕 Expert: Sätze + Wdh als Wheel-Picker nebeneinander
    private var expertSetsRepsSection: some View {
        Section {
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Sätze")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Sätze", selection: $sets) {
                        ForEach(1...6, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .clipped()
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("Wdh pro Satz")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Wdh pro Satz", selection: $repsPerSet) {
                        ForEach(8...15, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .clipped()
                }
                .frame(maxWidth: .infinity)
            }
        } header: {
            Text("Trainingsumfang")
        } footer: {
            Text("\(sets) × \(repsPerSet) Wiederholungen")
        }
    }

    private var expertPauseSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pause zwischen Sätzen").font(.subheadline)
                    Spacer()
                    Text("\(pauseSeconds) Sek")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accent)
                }
                Slider(
                    value: Binding(
                        get: { Double(pauseSeconds) },
                        set: { pauseSeconds = Int($0) }
                    ),
                    in: 0...180,
                    step: 5
                )
                .tint(.accent)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Pause")
        }
    }

    // Standard: alles wie bisher

    private var standardRepetitionsSection: some View {
        Section {
            HStack {
                Label("Wiederholungen", systemImage: "repeat")
                Spacer()
                HStack(spacing: 16) {
                    Button {
                        if repetitions > 1 { repetitions -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(repetitions > 1 ? .accent : .gray)
                    }
                    .buttonStyle(.plain)

                    Text("\(repetitions)×")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(minWidth: 40, alignment: .center)

                    Button {
                        if repetitions < 10 { repetitions += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Wiederholungen")
        }
    }

    private var standardLoopDurationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Dauer pro Wiederholung").font(.subheadline)
                    Spacer()
                    Text(formatDuration(loopDurationSeconds))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accent)
                }
                Slider(
                    value: Binding(
                        get: { Double(loopDurationSeconds) },
                        set: { loopDurationSeconds = Int($0) }
                    ),
                    in: 10...300,
                    step: 10
                )
                .tint(.accent)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Video-Dauer")
        }
    }

    private var standardPauseSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pause zwischen Wiederholungen").font(.subheadline)
                    Spacer()
                    Text("\(pauseSeconds) Sek")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accent)
                }
                Slider(
                    value: Binding(
                        get: { Double(pauseSeconds) },
                        set: { pauseSeconds = Int($0) }
                    ),
                    in: 0...120,
                    step: 5
                )
                .tint(.accent)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Pause")
        }
    }

    private var planModeSection: some View {
        Section {
            Button {
                selectedPlanMode = "single"
            } label: {
                HStack {
                    Image(systemName: selectedPlanMode == "single" ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.accent)
                    Text("Nur heute")
                }
            }
            .buttonStyle(.plain)

            Button {
                selectedPlanMode = activeMode
            } label: {
                HStack {
                    Image(systemName: selectedPlanMode == activeMode ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.accent)
                    Text(activeMode == "daily" ? "Zum Tagesplan hinzufügen" : "Zum Wochenplan hinzufügen")
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Einplanen als")
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return s > 0 ? "\(m):\(String(format: "%02d", s)) Min" : "\(m) Min"
    }
}

// MARK: - Int.clamped Helper

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Video.self, VideoSchedule.self, TempoProtocol.self,
        configurations: config
    )

    let video = Video(
        title: "Bizeps-Curls",
        videoFileName: "test.mp4",
        category: .strength,
        bodyRegion: .fullBody,
        equipment: .noEquipment,
        durationSeconds: 60,
        loopDurationSeconds: 60,
        rating: 3
    )
    video.tempoProtocol = TempoProtocol(
        concentricSec: 2, holdSec: 0, eccentricSec: 3,
        sets: 3, reps: 12, restBetweenSetsSec: 60,
        subtype: .dynamic
    )

    return VideoQuickConfigSheet(
        video: video,
        onAdd: { reps, loop, pause, mode, weight, sets, repsPerSet in
            print("reps:\(reps) loop:\(loop) pause:\(pause) mode:\(mode) weight:\(String(describing: weight)) sets:\(String(describing: sets)) repsPerSet:\(String(describing: repsPerSet))")
        },
        onCancel: {}
    )
    .modelContainer(container)
}
