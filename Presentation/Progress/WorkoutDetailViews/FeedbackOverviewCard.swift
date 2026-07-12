//
//  FeedbackOverviewCard.swift
//  Agil
//
//  Übersichts-Card für Feedback-Verlauf. Zeitraum-Navigation Apple-Health-Style.
//  Normalisiert Rating (1–5) und progressFeedback (0–1) einheitlich.
//

import SwiftUI
import AgilCore


struct FeedbackOverviewCard: View {
    @EnvironmentObject var historyVM: WorkoutHistoryViewModel
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var mode: TimeRangeMode = .month
    @State private var offset: Int = 0

    var body: some View {
        NavigationLink(destination: FeedbackDetailView()) {
            VStack(alignment: .leading, spacing: 12) {
                header
                TimeRangeSelector(mode: $mode, offset: $offset)
                MetricChartView(
                    points: filteredPoints,
                    lineColor: themeManager.currentTheme.accentColor,
                    yDomain: 0...1,
                    timeRangeMode: mode,
                    xStart: mode.range(offset: offset).start,
                    xEnd: mode.range(offset: offset).end,
                    valueLabel: { String(format: "%.0f%%", $0 * 100) }
                )
                detailHint
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .onChange(of: mode)   { load() }
        .onChange(of: offset) { load() }
        .onAppear { load() }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Feedback-Verlauf")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Durchschnitt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(currentLabel)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                trendLabel
            }
        }
    }

    private var detailHint: some View {
        HStack {
            Spacer()
            Text("Details")
                .font(.caption)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var trendLabel: some View {
        if let trend = historyVM.feedbackTrend {
            let isUp = trend >= 0
            HStack(spacing: 4) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text("\(isUp ? "+" : "")\(Int((trend * 100).rounded()))% vs Vorperiode")
                    .font(.caption)
            }
            .foregroundStyle(isUp ? .green : .red)
        } else {
            Text(" ").font(.caption)
        }
    }

    // MARK: - Computed

    private var filteredPoints: [MetricPoint] {
        let (start, end) = mode.range(offset: offset)
        return historyVM.feedbackPoints.filter { $0.date >= start && $0.date < end }
    }

    private var currentLabel: String {
        guard let avg = filteredPoints.map(\.value).average else { return "—" }
        return String(format: "%.0f%%", avg * 100)
    }

    // MARK: - Load

    private func load() {
        guard let user = session.currentUser else { return }
        historyVM.loadFeedbackOverview(for: user, granularity: mode.granularity)
    }
}

private extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
