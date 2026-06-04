import SwiftUI
import Charts

struct MetricChartView: View {
    let points: [MetricPoint]
    let lineColor: Color
    let yDomain: ClosedRange<Double>?
    let valueLabel: (Double) -> String
    var timeRangeMode: TimeRangeMode = .month
    var xStart: Date? = nil
    var xEnd: Date? = nil

    init(
        points: [MetricPoint],
        lineColor: Color = .accentColor,
        yDomain: ClosedRange<Double>? = nil,
        timeRangeMode: TimeRangeMode = .month,
        xStart: Date? = nil,
        xEnd: Date? = nil,
        valueLabel: @escaping (Double) -> String = { String(format: "%.2f", $0) }
    ) {
        self.points = points
        self.lineColor = lineColor
        self.yDomain = yDomain
        self.timeRangeMode = timeRangeMode
        self.xStart = xStart
        self.xEnd = xEnd
        self.valueLabel = valueLabel
    }

    var body: some View {
        if points.isEmpty {
            emptyState
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Datum", point.date),
                y: .value("Wert", point.value)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(lineColor)

            PointMark(
                x: .value("Datum", point.date),
                y: .value("Wert", point.value)
            )
            .foregroundStyle(lineColor)
            .symbolSize(40)
        }
        .chartYScale(domain: yDomain ?? autoDomain)
        .chartXScale(domain: xDomainRange)
        .chartXAxis { xAxisMarks }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(valueLabel(d))
                    }
                }
            }
        }
        .environment(\.timeZone, TimeZone.current)
        .frame(height: 180)
    }

    private var xDomainRange: ClosedRange<Date> {
        if let s = xStart, let e = xEnd {
            return s...e
        }
        let dates = points.map(\.date)
        guard let mn = dates.min(), let mx = dates.max() else {
            return Date()...Date()
        }
        return mn...mx
    }

    @AxisContentBuilder
    private var xAxisMarks: some AxisContent {
        switch timeRangeMode {
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

    private var autoDomain: ClosedRange<Double> {
        let values = points.map(\.value)
        guard let mn = values.min(), let mx = values.max() else { return 0...1 }
        if mn == mx { return (mn - 1)...(mx + 1) }
        let pad = (mx - mn) * 0.1
        return (mn - pad)...(mx + pad)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("Noch keine Daten")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
}
