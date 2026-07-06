//
//  KGGPatientHistoryView.swift
//  AgilKGG
//
//  Patienten-Historie: Alle Änderungen eines Patienten,
//  gruppiert nach Datum. Mit Übungsname, Thumbnail, dezenten Badges.
//

import SwiftUI
import SwiftData
import AgilCore

struct KGGPatientHistoryView: View {
    @StateObject private var viewModel: KGGPatientHistoryViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    private var accent: Color { themeManager.currentTheme.accentColor }

    init(patientId: UUID, patientNumber: String, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: KGGPatientHistoryViewModel(
            patientId: patientId,
            patientNumber: patientNumber,
            modelContext: modelContext
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.entries.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("Historie \(viewModel.patientNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { viewModel.load() }
        }
    }

    // MARK: - Liste

    private var historyList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.groupedByDate) { group in
                    daySection(group)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Tag-Sektion

    private func daySection(_ group: KGGPatientHistoryViewModel.DayGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(group.date)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                    entryRow(entry)

                    if index < group.entries.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        }
    }

    // MARK: - Eintrags-Zeile

    private func entryRow(_ entry: KGGExerciseHistory) -> some View {
        let isSimpleAction = entry.action == .created || entry.action == .deleted

        return VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .top, spacing: 10) {
                thumbnailView(for: entry)

                VStack(alignment: .leading, spacing: 4) {
                    // Name + Datum
                    HStack(alignment: .firstTextBaseline) {
                        Text(entry.exerciseName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(entry.formattedDate)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Changes direkt unter Name, Badge rechts daneben
                    ZStack(alignment: .topTrailing) {
                                            if !isSimpleAction {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    ForEach(entry.changes.components(separatedBy: ", "), id: \.self) { line in
                                                        Text(line)
                                                            .font(.caption)
                                                            .foregroundStyle(.secondary)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            HStack {
                                                Spacer()
                                                actionBadge(entry.action)
                                            }
                                        }
                }
                
                
            }

            // created/deleted: changes linksbündig unter Thumbnail
            if isSimpleAction {
                            Text(entry.changes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

            // Notiz
            if let notes = entry.notes, !notes.isEmpty {
                noteView(notes)
            }
        }
        .padding(16)
    }
    
    // MARK: - Thumbnail

    private func thumbnailView(for entry: KGGExerciseHistory) -> some View {
        Group {
            if let data = viewModel.thumbnail(for: entry),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color(.systemGray5)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Notiz (Akzentlinie)

    private func noteView(_ text: String) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(accent.opacity(0.6))
                .frame(width: 3)
                .clipShape(Capsule())

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .padding(.trailing, 8)
        .background(accent.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Action Badge (dezent, Pill)

    private func actionBadge(_ action: KGGExerciseHistory.HistoryAction) -> some View {
        Text(action.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(badgeColor(action).opacity(0.12))
            .foregroundStyle(badgeColor(action))
            .clipShape(Capsule())
    }

    private func badgeColor(_ action: KGGExerciseHistory.HistoryAction) -> Color {
        switch action {
        case .created:  return .green
        case .updated:  return accent
        case .deleted:  return .red
        case .paused:   return .orange
        case .resumed:  return .teal
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Keine Einträge")
                .font(.headline)
            Text("Sobald Übungen angelegt, geändert oder gelöscht werden, erscheint das hier.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
