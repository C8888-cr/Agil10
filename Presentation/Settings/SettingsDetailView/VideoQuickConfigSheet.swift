//
//  VideoQuickConfigSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 14.03.26.
//


import SwiftUI
import SwiftData

struct VideoQuickConfigSheet: View {
    let video: Video
    
    @State private var repetitions: Int
    @State private var loopDurationSeconds: Int
    @State private var pauseSeconds: Int
    
    let onAdd: (Int, Int, Int) -> Void // reps, loopDuration, pause
    let onCancel: () -> Void
    
    init(
        video: Video,
        initialRepetitions: Int? = nil,
        initialLoopDuration: Int? = nil,
        initialPause: Int? = nil,
        onAdd: @escaping (Int, Int, Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.video = video
        self.onAdd = onAdd
        self.onCancel = onCancel
        _repetitions = State(initialValue: initialRepetitions ?? video.defaultRepetitions)
        _loopDurationSeconds = State(initialValue: initialLoopDuration ?? video.loopDurationSeconds)
        _pauseSeconds = State(initialValue: initialPause ?? video.defaultPauseSeconds)
    }
    
    var totalSeconds: Int {
        (loopDurationSeconds * repetitions) + (pauseSeconds * max(0, repetitions - 1))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Video Info
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(video.title)
                                .font(.headline)
                            Text(video.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        // Gesamtdauer
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
                
                // Wiederholungen
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
                
                // Loop-Dauer
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Dauer pro Wiederholung")
                                .font(.subheadline)
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
                
                // Pause
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Pause zwischen Wiederholungen")
                                .font(.subheadline)
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
            .navigationTitle("Video konfigurieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hinzufügen") {
                        onAdd(repetitions, loopDurationSeconds, pauseSeconds)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.accent)
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return s > 0 ? "\(m):\(String(format: "%02d", s)) Min" : "\(m) Min"
    }
}
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Video.self, VideoSchedule.self,
        configurations: config
    )
    
    let video = Video(
        title: "Ganzkörper",
        videoFileName: "test.mp4",
        category: .mobility,
        bodyRegion: .fullBody,
        equipment: .noEquipment,
        durationSeconds: 120,
        loopDurationSeconds: 120,
        rating: 3
    )

    VideoQuickConfigSheet(
        video: video,
        onAdd: { reps, loop, pause in
            print("✅ reps: \(reps), loop: \(loop), pause: \(pause)")
        },
        onCancel: {
            print("❌ Abgebrochen")
        }
    )
    .modelContainer(container)
}
