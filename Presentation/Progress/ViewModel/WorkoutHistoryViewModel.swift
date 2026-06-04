
//
//  WorkoutHistoryViewModel.swift
//  Agil
//
//  ViewModel für Charts auf Basis der WorkoutLog-Historie.
//  Hält pro Metrik die aggregierten Punkte und ein Summary.
//

import SwiftUI
import Combine

@MainActor
final class WorkoutHistoryViewModel: ObservableObject {
    @Published private(set) var feedbackPoints: [MetricPoint] = []
        @Published private(set) var feedbackSummary: MetricAggregator.Summary =
            .init(average: nil, max: nil, min: nil, count: 0)

        /// Aktueller Monatswert (letzter Punkt in feedbackPoints).
        @Published private(set) var feedbackCurrent: Double?
        /// Veränderung in Prozentpunkten vs. Vormonat (z.B. +0.05 = +5pp).
        @Published private(set) var feedbackTrend: Double?
    // MARK: - Weight
    @Published private(set) var weightPoints: [MetricPoint] = []
    @Published private(set) var weightSummary: MetricAggregator.Summary =
        .init(average: nil, max: nil, min: nil, count: 0)
    @Published private(set) var weightCurrent: Double?
    @Published private(set) var weightTrend: Double?

    // MARK: - Per-Video
    @Published private(set) var videoFeedbackPoints: [MetricPoint] = []
    @Published private(set) var videoWeightPoints: [MetricPoint] = []
    @Published private(set) var selectedVideoTitle: String = ""
    
    // MARK: - Einzeleinträge für Detailansicht
    @Published private(set) var selectedVideoEntries: [WorkoutEntry] = []
    @Published var entryPageIndex: Int = 0

    struct WorkoutEntry: Identifiable {
        let id: UUID
        let date: Date
        let value: Double
    }
    

    // MARK: - Available Videos (für Liste in DetailView)
    @Published private(set) var feedbackVideos: [VideoSummary] = []
    @Published private(set) var weightVideos: [VideoSummary] = []
    
    @Published private(set) var isLoading = false
    @Published var error: Error?

    private let session: SessionManager
    private let fetchUseCase: FetchWorkoutLogsUseCase
    private let videoRepository: VideoRepositoryProtocol
    @Published private(set) var thumbnailCache: [UUID: UIImage] = [:]

    init(
        session: SessionManager,
        fetchUseCase: FetchWorkoutLogsUseCase,
        videoRepository: VideoRepositoryProtocol
    ) {
        self.session = session
        self.fetchUseCase = fetchUseCase
        self.videoRepository = videoRepository
    }

    /// Lädt Feedback-Punkte für die letzten 12 Monate, aggregiert pro Monat.
    /// Defaults bewusst hier (nicht im UseCase) — UI-Entscheidung.
    func loadFeedbackOverview(for user: User) {
        
        isLoading = true
        defer { isLoading = false }

        do {
            let logs = try fetchUseCase.executeAll(for: user.id)
            
            // DEBUG - danach wieder löschen
                   print("📋 Logs count: \(logs.count)")
                   print("📋 Alle Logs: \(logs.map { "date:\($0.date) feedback:\(String(describing: $0.progressFeedback)) rating:\(String(describing: $0.rating)) videoTitle:\($0.videoTitle)" })")
                   
            let points = MetricAggregator.aggregate(
                logs: logs,
                
                
                granularity: .month,
                valueSelector: MetricAggregator.feedbackSelector
            )
            self.feedbackPoints = points
            self.feedbackSummary = MetricAggregator.summary(points)
            self.feedbackCurrent = points.last?.value
                if points.count >= 2 {
                    let last = points[points.count - 1].value
                    let prev = points[points.count - 2].value
                    self.feedbackTrend = last - prev
                } else {
                    self.feedbackTrend = nil
                }
            } catch {
            self.error = error
        }
        
    }
    
    
    struct VideoSummary: Identifiable, Equatable {
        let id: UUID
        let title: String
        let average: Double
        let count: Int
       
    }
    
    func loadWeightOverview(for user: User, granularity: MetricGranularity = .month) {
        isLoading = true
        defer { isLoading = false }
        do {
            let logs = try fetchUseCase.executeAll(for: user.id)
            let points = MetricAggregator.aggregate(
                logs: logs,
                granularity: granularity,
                valueSelector: MetricAggregator.weightSelector
            )
            self.weightPoints = points
            self.weightSummary = MetricAggregator.summary(points)
            self.weightCurrent = points.last?.value
            if points.count >= 2 {
                let last = points[points.count - 1].value
                let prev = points[points.count - 2].value
                self.weightTrend = last - prev
            } else {
                self.weightTrend = nil
            }
            // Videos mit Gewicht aggregieren
            self.weightVideos = buildVideoSummaries(
                logs: logs,
                selector: MetricAggregator.weightSelector
            )
        } catch {
            self.error = error
        }
    }

    func loadFeedbackOverview(for user: User, granularity: MetricGranularity = .month) {
        isLoading = true
        defer { isLoading = false }
        do {
            let logs = try fetchUseCase.executeAll(for: user.id)
            
            print("📋 Alle Logs raw: \(logs.map { "\($0.date) feedback:\(String(describing: $0.progressFeedback)) rating:\(String(describing: $0.rating))" })")
            
            
            // Feedback: rating normalisieren (1–5 → 0–1) oder progressFeedback direkt
            let normalizedSelector: (WorkoutLog) -> Double? = { log in
                if let pf = log.progressFeedback { return pf }
                if let r = log.rating { return Double(r) / 5.0 }
                return nil
            }
            let points = MetricAggregator.aggregate(
                logs: logs,
                granularity: granularity,
                valueSelector: normalizedSelector
            )
            self.feedbackPoints = points
            self.feedbackSummary = MetricAggregator.summary(points)
            self.feedbackCurrent = points.last?.value
            if points.count >= 2 {
                let last = points[points.count - 1].value
                let prev = points[points.count - 2].value
                self.feedbackTrend = last - prev
            } else {
                self.feedbackTrend = nil
            }
            self.feedbackVideos = buildVideoSummaries(
                logs: logs,
                selector: normalizedSelector
            )
        } catch {
            self.error = error
        }
    }

    func loadVideoFeedback(videoId: UUID, title: String, for user: User, granularity: MetricGranularity = .month) {
        do {
            let logs = try fetchUseCase.execute(videoId: videoId, userId: user.id)
            let completions = logs.filter { $0.entryTypeEnum == .completion }
            let normalizedSelector: (WorkoutLog) -> Double? = { log in
                if let pf = log.progressFeedback { return pf }
                if let r = log.rating { return Double(r) / 5.0 }
                return nil
            }
            // Direkt aggregieren ohne activeCompletions-Filter —
            // damit alle Feedback-Einträge des Tages einfließen
            let calendar = Calendar.current
            var buckets: [Date: [Double]] = [:]
            for log in completions {
                guard let value = normalizedSelector(log) else { continue }
                let bucket = granularity.startOfPeriod(for: log.date, calendar: calendar)
                buckets[bucket, default: []].append(value)
            }
            self.videoFeedbackPoints = buckets
                .map { date, values in
                    MetricPoint(
                        date: date,
                        value: values.reduce(0, +) / Double(values.count),
                        count: values.count
                    )
                }
                .sorted { $0.date < $1.date }
            self.selectedVideoTitle = title
        } catch {
            self.error = error
        }
    }
    
    
    func loadVideoWeight(videoId: UUID, title: String, for user: User, granularity: MetricGranularity = .month) {
        do {
            let logs = try fetchUseCase.execute(videoId: videoId, userId: user.id)
            
            // DEBUG
            print("🏋️ loadVideoWeight für: \(title)")
            print("🏋️ Logs: \(logs.map { "date:\($0.date) weightKg:\(String(describing: $0.weightKg))" })")
            
            self.videoWeightPoints = MetricAggregator.aggregate(
                logs: logs,
                granularity: granularity,
                valueSelector: MetricAggregator.weightSelector
            )
            
            print("🏋️ videoWeightPoints: \(self.videoWeightPoints.map { "\($0.date) → \($0.value)" })")
            
            self.selectedVideoTitle = title
        } catch {
            self.error = error
        }
    }
    
    
    // MARK: - Private Helper

    private func buildVideoSummaries(
        logs: [WorkoutLog],
        selector: (WorkoutLog) -> Double?
    ) -> [VideoSummary] {
        let active = MetricAggregator.activeCompletions(logs)
        var grouped: [UUID: (title: String, values: [Double])] = [:]
        for log in active {
            guard let vid = log.videoId, let value = selector(log) else { continue }
            if grouped[vid] == nil {
                grouped[vid] = (title: log.videoTitle, values: [])
            }
            grouped[vid]?.values.append(value)
        }
        return grouped
            .map { id, data in
                VideoSummary(
                    id: id,
                    title: data.title,
                    average: data.values.reduce(0, +) / Double(data.values.count),
                    count: data.values.count
               
                    
                )
            }
            .sorted { $0.title < $1.title }
    }
    
    /// Für Feedback-Verlauf: alle Completions behalten (nicht nur letzte pro Schedule).
    /// Korrekturen (correction) werden trotzdem rausgefiltert.
    private static func allCompletions(_ logs: [WorkoutLog]) -> [WorkoutLog] {
        logs.filter { $0.entryTypeEnum == .completion }
    }
    
    
    func loadThumbnail(for videoId: UUID) {
        guard thumbnailCache[videoId] == nil else { return }
        Task {
            guard let video = try? await videoRepository.fetchVideo(by: videoId),
                  let fileName = video.thumbnailFileName,
                  let image = ThumbnailGeneratorService.shared.loadThumbnail(fileName: fileName)
            else { return }
            thumbnailCache[videoId] = image
        }
    }
    func loadVideoEntries(videoId: UUID, userId: UUID, selector: @escaping (WorkoutLog) -> Double?) {
        do {
            let logs = try fetchUseCase.execute(videoId: videoId, userId: userId)
            let active = MetricAggregator.activeCompletions(logs)
            self.selectedVideoEntries = active
                .compactMap { log -> WorkoutEntry? in
                    guard let value = selector(log) else { return nil }
                    return WorkoutEntry(id: log.id, date: log.date, value: value)
                }
                .sorted { $0.date > $1.date } // neueste zuerst
            self.entryPageIndex = 0
        } catch {
            self.error = error
        }
    }

    /// Sichtbare Einträge für die aktuelle Seite (3 pro Seite).
    var visibleEntries: [WorkoutEntry] {
        let start = entryPageIndex * 3
        guard start < selectedVideoEntries.count else { return [] }
        let end = min(start + 3, selectedVideoEntries.count)
        return Array(selectedVideoEntries[start..<end])
    }

    var canPageEntriesBack: Bool { entryPageIndex > 0 }
    var canPageEntriesForward: Bool { (entryPageIndex + 1) * 3 < selectedVideoEntries.count }
}
