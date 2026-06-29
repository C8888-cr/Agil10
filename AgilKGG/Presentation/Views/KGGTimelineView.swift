//
//  KGGTimelineView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 27.06.26.
//


//
//  KGGTimelineView.swift
//  AgilKGG
//
//  Timeline: Alle Änderungen an einer Übung gruppiert nach Datum
//

import SwiftUI
import SwiftData
import AgilCore

struct KGGTimelineView: View {
    @StateObject private var viewModel: KGGTimelineViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    let exerciseId: UUID
    let exerciseTitle: String
    let patientId: UUID
    let modelContext: ModelContext
    
    init(exerciseId: UUID, exerciseTitle: String, patientId: UUID, modelContext: ModelContext) {
        self.exerciseId = exerciseId
        self.exerciseTitle = exerciseTitle
        self.patientId = patientId
        self.modelContext = modelContext
        _viewModel = StateObject(wrappedValue: KGGTimelineViewModel(exerciseId: exerciseId, patientId: patientId, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Filter
                    if !viewModel.allActions.isEmpty {
                        filterBar
                    }
                    
                    // Timeline
                    if viewModel.filteredEntries.isEmpty {
                        emptyState
                    } else {
                        timelineList
                    }
                }
            }
            .navigationTitle("Änderungshistorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadHistory()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exerciseTitle)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("\(viewModel.historyEntries.count) Einträge")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    viewModel.clearFilter()
                } label: {
                    Text("Alle")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.selectedActionFilter == nil ? themeManager.currentTheme.accentColor : Color(.systemGray5))
                        .foregroundStyle(viewModel.selectedActionFilter == nil ? .white : .primary)
                        .cornerRadius(16)
                }
                
                ForEach(viewModel.allActions, id: \.self) { action in
                    Button {
                        if viewModel.selectedActionFilter == action {
                            viewModel.clearFilter()
                        } else {
                            viewModel.selectedActionFilter = action
                            viewModel.applyFilters()
                        }
                    } label: {
                        Text(action.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.selectedActionFilter == action ? themeManager.currentTheme.accentColor : Color(.systemGray5))
                            .foregroundStyle(viewModel.selectedActionFilter == action ? .white : .primary)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(12)
        }
        .background(Color.white)
    }
    
    private var timelineList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(viewModel.groupedByDate.sorted(by: { $0.key > $1.key })), id: \.key) { date, entries in
                    timelineSection(date: date, entries: entries)
                }
            }
            .padding(16)
        }
    }
    
    private func timelineSection(date: String, entries: [KGGExerciseHistory]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
            
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    timelineEntryRow(entry)
                    
                    if index < entries.count - 1 {
                        Divider()
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private func timelineEntryRow(_ entry: KGGExerciseHistory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        actionBadge(entry.action)
                        
                        Text(entry.changedBy)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Text(entry.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Text(entry.changes)
                .font(.caption)
                .lineLimit(2)
                .foregroundStyle(.secondary)
            
            if let notes = entry.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notiz")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(.primary)
                }
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(6)
            }
        }
    }
    
    private func actionBadge(_ action: KGGExerciseHistory.HistoryAction) -> some View {
        Text(action.rawValue)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(actionColor(action))
            .foregroundStyle(.white)
            .cornerRadius(4)
    }
    
    private func actionColor(_ action: KGGExerciseHistory.HistoryAction) -> Color {
        switch action {
        case .created: return .green
        case .updated: return .blue
        case .deleted: return .red
        case .paused: return .orange
        case .resumed: return .green
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            VStack(spacing: 8) {
                Text("Keine Änderungen")
                    .font(.headline)
                Text("Bisher wurden keine Änderungen an dieser Übung vorgenommen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KGGExerciseHistory.self, configurations: config)
    
    KGGTimelineView(
        exerciseId: UUID(),
        exerciseTitle: "Test Übung",
        patientId: UUID(),
        modelContext: container.mainContext
    )
    .environmentObject(ThemeManager())
}