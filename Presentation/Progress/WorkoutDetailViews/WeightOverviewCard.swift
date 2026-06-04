//
//  WeightOverviewCard.swift
//  Agil10.0
//
//  Created by Christiane Roth on 02.06.26.
//


//
//  WeightOverviewCard.swift
//  Agil
//
//  Übersichts-Card für Gewichtsverlauf. Nur Videos mit weightKg != nil.
//  Gleiche Struktur wie FeedbackOverviewCard.
//

import SwiftUI

struct WeightOverviewCard: View {
    @EnvironmentObject var historyVM: WorkoutHistoryViewModel
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var mode: TimeRangeMode = .month
    @State private var offset: Int = 0

    var body: some View {
        NavigationLink(destination: WeightDetailView()) {
            VStack(alignment: .leading, spacing: 12) {
                header
                TimeRangeSelector(mode: $mode, offset: $offset)
                if filteredPoints.isEmpty {
                    emptyState
                } else {
                    MetricChartView(
                        points: filteredPoints,
                        lineColor: themeManager.currentTheme.accentColor,
                        yDomain: nil,
                        timeRangeMode: mode,
                        xStart: mode.range(offset: offset).start,
                        xEnd: mode.range(offset: offset).end,
                        valueLabel: { String(format: "%.1f kg", $0) }
                    )
                }
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
                Text("Gewichtsverlauf")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Eingesetztes Gewicht")
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
        if let trend = historyVM.weightTrend {
            let isUp = trend >= 0
            HStack(spacing: 4) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text("\(isUp ? "+" : "")\(String(format: "%.1f", trend)) kg vs Vorperiode")
                    .font(.caption)
            }
            .foregroundStyle(isUp ? .green : .red)
        } else {
            Text(" ").font(.caption)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "scalemass")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Noch keine Gewichtsdaten")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }

    // MARK: - Computed

    private var filteredPoints: [MetricPoint] {
        let (start, end) = mode.range(offset: offset)
        return historyVM.weightPoints.filter { $0.date >= start && $0.date < end }
    }

    private var currentLabel: String {
        guard let avg = filteredPoints.map(\.value).average else { return "—" }
        return String(format: "%.1f kg", avg)
    }

    // MARK: - Load

    private func load() {
        guard let user = session.currentUser else { return }
        historyVM.loadWeightOverview(for: user, granularity: mode.granularity)
    }
}

private extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
