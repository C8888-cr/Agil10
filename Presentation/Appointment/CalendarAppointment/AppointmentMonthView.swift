//
//  AppointmentMonthView.swift
//  Agil10.0
//
//  Vertikal scrollbarer Monatskalender. Apple-Style.
//  Wird von AppointmentView orchestriert – kein eigener Day/Year-Cover.
//

import SwiftUI
import SwiftData
import AgilCore


struct AppointmentMonthView: View {

    @ObservedObject var viewModel: AppointmentPlannerViewModel
    @EnvironmentObject var themeManager: ThemeManager

    /// Initialer Monat, zu dem gescrollt wird
    let initialMonth: Date

    /// Callbacks – Orchestrierung liegt bei AppointmentView
    var onDaySelected: (Date) -> Void
    var onYearTapped: () -> Void
    var onCloseAll: () -> Void

    /// Monat, der gerade oben im sticky Header angezeigt wird
    @State private var visibleMonth: Date
    /// Trigger: zu welchem Monat soll gescrollt werden?
    @State private var scrollTarget: Date? = nil

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Montag
        return cal
    }()

    private let stickyHeaderHeight: CGFloat = 86

    init(
        viewModel: AppointmentPlannerViewModel,
        initialMonth: Date = Date(),
        onDaySelected: @escaping (Date) -> Void,
        onYearTapped: @escaping () -> Void,
        onCloseAll: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.initialMonth = initialMonth
        self.onDaySelected = onDaySelected
        self.onYearTapped = onYearTapped
        self.onCloseAll = onCloseAll
        _visibleMonth = State(initialValue: initialMonth)
    }

    private var monthAnchors: [Date] {
        let base = startOfMonth(initialMonth)
        return (-24...24).compactMap {
            calendar.date(byAdding: .month, value: $0, to: base)
        }
    }

    private var currentYear: Int {
        calendar.component(.year, from: visibleMonth)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        Color.clear.frame(height: stickyHeaderHeight)

                        LazyVStack(spacing: 0) {
                            ForEach(monthAnchors, id: \.self) { monthStart in
                                monthBlock(monthStart: monthStart)
                                    .id(monthStart)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(
                                                key: MonthFramesKey.self,
                                                value: [MonthFrame(
                                                    monthStart: monthStart,
                                                    minY: geo.frame(in: .named("scrollSpace")).minY
                                                )]
                                            )
                                        }
                                    )
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .coordinateSpace(name: "scrollSpace")
                    .onPreferenceChange(MonthFramesKey.self) { frames in
                        updateVisibleMonth(from: frames)
                    }
                    .onAppear {
                        DispatchQueue.main.async {
                            let target = startOfMonth(initialMonth)
                            proxy.scrollTo(target, anchor: .top)
                        }
                    }
                    .onChange(of: scrollTarget) { _, newTarget in
                        guard let newTarget else { return }
                        let target = startOfMonth(newTarget)
                        withAnimation {
                            proxy.scrollTo(target, anchor: .top)
                        }
                        scrollTarget = nil
                    }
                }

                stickyHeader
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // < 2026 → YearView
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onYearTapped()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text(String(currentYear))
                                .font(.body.weight(.semibold))
                        }
                        .foregroundStyle(themeManager.currentTheme.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .glassEffect(in: Capsule())
                    }
                }

                // X → AppointmentView
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onCloseAll()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(themeManager.currentTheme.accentColor)
                            .frame(width: 32, height: 32)
                            .glassEffect(in: Circle())
                    }
                }
            }
            // Heute
            .overlay(alignment: .bottomLeading) {
                Button {
                    scrollTarget = Date()
                } label: {
                    Text("Heute")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.accentColor)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .glassEffect(in: Capsule())
                }
                .padding(.leading, 16)
                .padding(.bottom, 20)
            }
            .task {
                await loadEvents()
            }
        }
    }

    // MARK: - Sticky Header

    private var stickyHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(monthFormatter.string(from: visibleMonth))
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .animation(.easeInOut(duration: 0.15), value: visibleMonth)

            HStack(spacing: 0) {
                let weekdays = ["M", "D", "M", "D", "F", "S", "S"]
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(index >= 5 ? .secondary : .primary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)

            Divider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }

    // MARK: - Monatsblock

    private func monthBlock(monthStart: Date) -> some View {
        let weeksInMonth = weeksOfMonth(monthStart)

        return VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 32)

            inlineMonthTitle(for: monthStart)
                .padding(.bottom, 4)

            ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { index, weekDays in
                weekRow(weekDays: weekDays, monthStart: monthStart, isFirstWeek: index == 0)
            }
        }
    }

    private func inlineMonthTitle(for monthStart: Date) -> some View {
        let weekdayRaw = calendar.component(.weekday, from: monthStart)
        let columnIndex = (weekdayRaw + 5) % 7

        return GeometryReader { geo in
            let totalWidth = geo.size.width - 24
            let colWidth = totalWidth / 7
            let offsetX = CGFloat(columnIndex) * colWidth

            Text(monthFormatter.string(from: monthStart))
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.leading, 12 + offsetX)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 32)
    }

    private func weekRow(weekDays: [Date], monthStart: Date, isFirstWeek: Bool) -> some View {
        VStack(spacing: 0) {
            weekDivider(weekDays: weekDays, monthStart: monthStart, isFirstWeek: isFirstWeek)

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { col in
                    if col < weekDays.count, isInMonth(weekDays[col], monthStart: monthStart) {
                        dayCell(date: weekDays[col])
                            .onTapGesture {
                                onDaySelected(weekDays[col])
                            }
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private func weekDivider(weekDays: [Date], monthStart: Date, isFirstWeek: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { col in
                let drawLine: Bool = {
                    guard col < weekDays.count else { return false }
                    let day = weekDays[col]
                    guard isInMonth(day, monthStart: monthStart) else { return false }
                    if isFirstWeek { return false }
                    return true
                }()

                Rectangle()
                    .fill(drawLine ? Color(.separator) : Color.clear)
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
    }

    private func dayCell(date: Date) -> some View {
            let dayNumber = calendar.component(.day, from: date)
            let isToday = calendar.isDateInToday(date)
            let isWeekend = isWeekendDay(date)
            let dayKey = calendar.startOfDay(for: date)
            let hasEvents = viewModel.daysWithEventsIndex.contains(dayKey)
        
        
        return VStack(spacing: 4) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor)
                        .frame(width: 34, height: 34)
                }
                Text("\(dayNumber)")
                    .font(.system(size: 20, weight: isToday ? .bold : .regular))
                    .foregroundStyle(
                        isToday ? .white :
                        (isWeekend ? .secondary : .primary)
                    )
            }
            .frame(height: 36)

            RoundedRectangle(cornerRadius: 2.5)
                .fill(hasEvents ? Color("Blau") : Color.clear)
                .frame(width: 28, height: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .contentShape(Rectangle())
    }

    // MARK: - Sichtbaren Monat tracken

    private func updateVisibleMonth(from frames: [MonthFrame]) {
            let sorted = frames.sorted { $0.minY < $1.minY }
            let pivot = sorted.last(where: { $0.minY < stickyHeaderHeight }) ?? sorted.first
            guard let pivot else { return }

            if !calendar.isDate(pivot.monthStart, equalTo: visibleMonth, toGranularity: .month) {
                visibleMonth = pivot.monthStart
                // Lazy Load: Events für den neuen Monat ± 1 nachladen (no-op wenn schon im Cache)
                Task {
                    await viewModel.loadEventsIfNeeded(around: pivot.monthStart)
                }
            }
        }

    private func weeksOfMonth(_ monthStart: Date) -> [[Date]] {
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }

        var weeks: [[Date]] = []
        var currentWeek: [Date] = []

        let firstWeekdayRaw = calendar.component(.weekday, from: monthStart)
        let leadingEmpties = (firstWeekdayRaw + 5) % 7

        for i in 0..<leadingEmpties {
            if let d = calendar.date(byAdding: .day, value: -(leadingEmpties - i), to: monthStart) {
                currentWeek.append(d)
            }
        }

        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                currentWeek.append(d)
                if currentWeek.count == 7 {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
            }
        }

        if !currentWeek.isEmpty {
            let needed = 7 - currentWeek.count
            if let last = currentWeek.last {
                for i in 1...needed {
                    if let d = calendar.date(byAdding: .day, value: i, to: last) {
                        currentWeek.append(d)
                    }
                }
            }
            weeks.append(currentWeek)
        }

        return weeks
    }

    // MARK: - Helpers

    private func isInMonth(_ date: Date, monthStart: Date) -> Bool {
        calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
    }

    private func startOfMonth(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private func isWeekendDay(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "MMMM"
        return f
    }

    private func loadEvents() async {
            // Nur den initialen Monat ± 1 laden – Rest kommt lazy beim Scrollen
            await viewModel.loadEventsIfNeeded(around: initialMonth)
        }
}

private struct MonthFrame: Equatable {
    let monthStart: Date
    let minY: CGFloat
}

private struct MonthFramesKey: PreferenceKey {
    static var defaultValue: [MonthFrame] = []
    static func reduce(value: inout [MonthFrame], nextValue: () -> [MonthFrame]) {
        value.append(contentsOf: nextValue())
    }
}
