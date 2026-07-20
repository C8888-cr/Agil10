/*
import SwiftUI
import SwiftData


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

*/




import SwiftUI
import PhotosUI
import SwiftData
import AgilCore



struct VideoScheduleConfigSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let video: Video
    @State private var defaultRepetitions = 3
    @State private var defaultPauseSeconds = 30
    @State private var loopDurationSeconds: Int?
    @State private var useLoopDuration = false
    
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var showError = false
    
    @Binding var loopDuration: Int
    @Binding var repetitions: Int
    @Binding var pauseSeconds: Int
    
    @EnvironmentObject var themeManager: ThemeManager
    
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Form {
                    
                    // Repetitions & Pause
                    Section("Standard-Einstellungen") {
                        Stepper("Wiederholungen: \(repetitions)", value: $repetitions, in: 1...10)
                        
                        Stepper("Pause: \(pauseSeconds) Sek", value: $pauseSeconds, in: 0...180, step: 10)
                    }
                    
                    // Loop Duration (optional)
                    Section {
                        
                        
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Länge eines Videos")
                                Spacer()
                                Text(formatSeconds(loopDuration))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(themeManager.currentTheme.accentColor)
                            }
                            
                          
                            
                            Slider(
                                value: .init(
                                    get: { Double(loopDuration) },
                                    set: { loopDuration = Int($0) }
                                ),
                                in: 5...300,  // ✅ 5s bis 5min IMMER
                                step: 5
                            )
                            .tint(themeManager.currentTheme.accentColor)
                        }
                        
                    } header: {
                        Text("Video-Loop (optional)")
                    } footer: {
                        Text("Für kurze Videos, die mehrfach abgespielt werden sollen")
                    }
                    
                    
                    
                    .padding(.vertical, 4)
                    
                    
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
                                    .foregroundStyle(themeManager.currentTheme.accentColor)
                            }
                        }
                        .font(.subheadline)
                        
                    }
                    
                    
                    .padding(.vertical, 4)
                    
                }
                Button("Speichern") {
                    onAdd()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
            }
            
            
            
            
            
            
            .navigationTitle("Video konfigurieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .disabled(isUploading)
                }
            }
            .alert("Fehler", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(uploadError ?? "Unbekannter Fehler")
                
            }
            .onAppear {
                           // Wenn loopDuration nicht gesetzt (0 oder ungültig),
                           // dann auf Video-Dauer initialisieren
                           if loopDuration == 0 || loopDuration < 5 {
                               loopDuration = max(5, video.durationSeconds)
                               print("📝 Loop-Dauer initialisiert auf: \(loopDuration)s")
                           }
                       }
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
#Preview("Standard Video (2 Min)") {
    struct PreviewWrapper: View {
        @State private var repetitions = 3
        @State private var pauseSeconds = 30
        @State private var loopDuration = 0
        
        var body: some View {
            VideoScheduleConfigSheet(
                video: Video(
                    title: "Schulter Mobilisation",
                    videoFileName: "test.mp4",
                    category: .mobility,
                    bodyRegion: .back,
                    equipment: .noEquipment,
                    durationSeconds: 120,
                    fileSizeBytes: 25_000_000,
                    defaultRepetitions: 3,
                    defaultPauseSeconds: 30,
                    loopDurationSeconds: 120,
                    rating: 4
                ),
                loopDuration: $loopDuration,
                repetitions: $repetitions,
                pauseSeconds: $pauseSeconds,
                onAdd: { print("✅ Hinzugefügt") },
                onCancel: { print("❌ Abgebrochen") }
            )
            // ← kein environmentObject nötig!
        }
    }
    return PreviewWrapper()
}
