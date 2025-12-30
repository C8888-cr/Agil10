
import SwiftUI
struct VideoScheduleConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let video: Video
    @Binding var repetitions: Int
    @Binding var pauseSeconds: Int
    @Binding var loopDuration: Int
    
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                // Video Preview
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "video.fill")
                            .font(.title)
                            .foregroundStyle(.accent)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(video.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(video.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text(formatSeconds(video.durationSeconds))
                            }
                            .font(.caption)
                            .foregroundStyle(.accent)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Wiederholungen
                Section("Wiederholungen") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Wie oft wiederholen?")
                            Spacer()
                            Text("\(repetitions)×")
                                .fontWeight(.semibold)
                                .foregroundStyle(.accent)
                        }
                        
                        Slider(
                            value: .init(
                                get: { Double(repetitions) },
                                set: { repetitions = Int($0) }
                            ),
                            in: 1.0...10.0,
                            step: 1
                        )
                        .tint(.accent)
                    }
                    .padding(.vertical, 4)
                }
                
                // Pause
                Section("Pausen") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Pause zwischen Wiederholungen")
                            Spacer()
                            Text("\(pauseSeconds)s")
                                .fontWeight(.semibold)
                                .foregroundStyle(.accent)
                        }
                        
                        Slider(
                            value: .init(
                                get: { Double(pauseSeconds) },
                                set: { pauseSeconds = Int($0) }
                            ),
                            in: 0.0...180.0,
                            step: 15
                        )
                        .tint(.accent)
                    }
                    .padding(.vertical, 4)
                }
                
                // Video-Dauer
                Section("Video-Dauer") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Länge eines Loops")
                            Spacer()
                            Text(formatSeconds(loopDuration))
                                .fontWeight(.semibold)
                                .foregroundStyle(.accent)
                        }
                        
                        // ✅ KORRIGIERT: Berechnung ausgelagert
                        let sliderRange = calculateSliderRange()
                        
                        Slider(
                            value: .init(
                                get: { Double(loopDuration) },
                                set: { newValue in
                                    // ✅ Wert direkt clampen
                                    loopDuration = min(
                                        max(Int(newValue), sliderRange.min),
                                        sliderRange.max
                                    )
                                }
                            ),
                            in: Double(sliderRange.min)...Double(sliderRange.max),
                            step: 5
                        )
                        .tint(.accent)
                        
                        Text("Standard: \(formatSeconds(video.loopDurationSeconds))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // Zusammenfassung
                Section("Trainingszeit heute") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Pro Durchlauf:")
                            Spacer()
                            Text(formatSeconds(loopDuration))
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Wiederholungen:")
                            Spacer()
                            Text("×\(repetitions)")
                                .fontWeight(.semibold)
                        }
                        
                        if pauseSeconds > 0 {
                            HStack {
                                Text("Pausen:")
                                Spacer()
                                Text("\((repetitions - 1) * pauseSeconds)s")
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Gesamt:")
                                .fontWeight(.semibold)
                                .font(.headline)
                            Spacer()
                            Text(calculateTotal())
                                .fontWeight(.semibold)
                                .font(.headline)
                                .foregroundStyle(.accent)
                        }
                    }
                    .font(.subheadline)
                }
            }
            
            // ✅ KORRIGIERT: Buttons außerhalb der Form
            HStack(spacing: 16) {
                Button("Abbrechen") {
                    onCancel()
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                
                Spacer()
                
                Button("Speichern") {
                    print("✅ Video hinzugefügt: \(video.title)")
                    print("   Wiederholungen: \(repetitions)")
                    print("   Pause: \(pauseSeconds)s")
                    print("   Loop-Dauer: \(loopDuration)s")
                    onAdd()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("Training konfigurieren")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Abbrechen") {
                    onCancel()
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            // ✅ Loop-Dauer bei Anzeige clampen
            let range = calculateSliderRange()
            loopDuration = min(max(loopDuration, range.min), range.max)
        }
    }
    
    // ✅ NEU: Slider-Range berechnen (verhindert ungültige Werte)
    private func calculateSliderRange() -> (min: Int, max: Int) {
        let base = max(1, video.durationSeconds)  // Minimum: Video-Dauer
        let minDuration = base
        let hardMax = 300  // 5 Minuten
        let maxDuration = max(minDuration + 10, hardMax)
        
        return (minDuration, maxDuration)
    }
    
    private func calculateTotal() -> String {
        let totalSeconds = (loopDuration * repetitions) +
                          (max(0, repetitions - 1) * pauseSeconds)
        return formatSeconds(totalSeconds)
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if secs > 0 {
            return "\(minutes):\(String(format: "%02d", secs)) Min"
        }
        return "\(minutes) Min"
    }
}
// ✅ Preview
#Preview {
    let video = Video(
        title: "Schulter Mobilisation",
        videoFileName: "test.mp4",
        category: .mobility,
        bodyRegion: .cervicalSpine,
        equipment: .noEquipment,
        durationSeconds: 120,
        fileSizeBytes: 15_000_000,
        defaultRepetitions: 3,
        defaultPauseSeconds: 30,
        loopDurationSeconds: 120,
    
        rating: 4
    )
    
    NavigationStack {
        VideoScheduleConfigSheet(
            video: video,
            repetitions: .constant(3),
            pauseSeconds: .constant(15),
            loopDuration: .constant(120),
            onAdd: {
                print("✅ Preview: Video hinzugefügt")
            },
            onCancel: {
                print("❌ Preview: Abgebrochen")
            }
        )
    }
}
