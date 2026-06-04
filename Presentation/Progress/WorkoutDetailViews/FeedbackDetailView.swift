import SwiftUI
import Charts

struct FeedbackDetailView: View {
    @EnvironmentObject var historyVM: WorkoutHistoryViewModel
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var mode: TimeRangeMode = .week
    @State private var offset: Int = 0
    @State private var selectedVideo: WorkoutHistoryViewModel.VideoSummary?

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                chartCard
                    .frame(maxHeight: geo.size.height / 3 + 40)

                Divider()

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(historyVM.feedbackVideos) { video in
                            CompactVideoCard(
                                title: video.title,
                                subtitle: String(format: "Ø %.0f%%", video.average * 100),
                                count: video.count,
                                videoId: video.id,
                                isSelected: selectedVideo?.id == video.id,
                                onTap: {
                                    selectedVideo = video
                                    reloadVideo()
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Feedback-Verlauf")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: mode) { reloadVideo() }
        .onAppear { initialLoad() }
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedVideo?.title ?? "Kein Video")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            DetailTimeRangePicker(mode: $mode, offset: $offset)

            Text(mode.label(offset: offset))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            feedbackChart
                .frame(maxHeight: 120)

            entriesRow
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Feedback Chart

    @ViewBuilder
    private var feedbackChart: some View {
        if filteredVideoPoints.isEmpty {
            VStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Keine Daten")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(filteredVideoPoints) { point in
                LineMark(
                    x: .value("Datum", point.date),
                    y: .value("Feedback", point.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(themeManager.currentTheme.accentColor)

                PointMark(
                    x: .value("Datum", point.date),
                    y: .value("Feedback", point.value)
                )
                .foregroundStyle(themeManager.currentTheme.accentColor)
                .symbolSize(30)
            }
            .chartYScale(domain: 0...1)
            .chartXScale(domain: mode.range(offset: offset).start...mode.range(offset: offset).end)
            .chartXAxis { xAxisMarks }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0.0, 0.5, 1.0]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text(String(format: "%.0f%%", d * 100))
                                .font(.caption2)
                        }
                    }
                }
            }
            .environment(\.timeZone, TimeZone.current)
        }
    }

    @AxisContentBuilder
    private var xAxisMarks: some AxisContent {
        switch mode {
        case .week:
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        case .month:
            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
            }
        case .year:
            AxisMarks(values: .stride(by: .month, count: 1)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.narrow))
            }
        }
    }

    // MARK: - Einträge-Row

    private var entriesRow: some View {
        HStack(spacing: 0) {
            Button {
                historyVM.entryPageIndex -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        historyVM.canPageEntriesBack
                        ? themeManager.currentTheme.accentColor
                        : Color.secondary.opacity(0.3)
                    )
                    .frame(width: 24)
            }
            .buttonStyle(.plain)
            .disabled(!historyVM.canPageEntriesBack)

            if historyVM.visibleEntries.isEmpty {
                Text("Keine Einträge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 0) {
                    ForEach(historyVM.visibleEntries) { entry in
                        VStack(spacing: 2) {
                            Text(entry.date.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.0f%%", entry.value * 100))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            Button {
                historyVM.entryPageIndex += 1
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        historyVM.canPageEntriesForward
                        ? themeManager.currentTheme.accentColor
                        : Color.secondary.opacity(0.3)
                    )
                    .frame(width: 24)
            }
            .buttonStyle(.plain)
            .disabled(!historyVM.canPageEntriesForward)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Computed

    private var filteredVideoPoints: [MetricPoint] {
        let (start, end) = mode.range(offset: offset)
        return historyVM.videoFeedbackPoints.filter {
            $0.date >= start && $0.date < end
        }
    }

    // MARK: - Load

    private func initialLoad() {
        guard let user = session.currentUser else { return }
        historyVM.loadFeedbackOverview(for: user, granularity: mode.granularity)
        if selectedVideo == nil, let first = historyVM.feedbackVideos.first {
            selectedVideo = first
            loadVideoData(video: first)
        }
    }

    private func reloadVideo() {
        guard let video = selectedVideo else { return }
        loadVideoData(video: video)
    }

    private func loadVideoData(video: WorkoutHistoryViewModel.VideoSummary) {
        guard let user = session.currentUser else { return }
        let normalizedSelector: (WorkoutLog) -> Double? = { log in
            if let pf = log.progressFeedback { return pf }
            if let r = log.rating { return Double(r) / 5.0 }
            return nil
        }
        historyVM.loadVideoFeedback(
            videoId: video.id,
            title: video.title,
            for: user,
            granularity: mode.granularity
        )
        historyVM.loadVideoEntries(
            videoId: video.id,
            userId: user.id,
            selector: normalizedSelector
        )
    }
}
