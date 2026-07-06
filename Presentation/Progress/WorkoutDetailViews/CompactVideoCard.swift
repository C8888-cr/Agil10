//
//  CompactVideoCard.swift
//  Agil10.0
//
//  Created by Christiane Roth on 04.06.26.
//


import SwiftUI
import AgilCore

struct CompactVideoCard: View {
    let title: String
    let subtitle: String
    let count: Int
    let videoId: UUID
    let isSelected: Bool
    let onTap: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var historyVM: WorkoutHistoryViewModel

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Thumbnail
                thumbnailView
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(subtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(count) Einträge")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }
            .padding(10)
            .background(
                isSelected
                ? themeManager.currentTheme.accentColor.opacity(0.08)
                : Color(.secondarySystemGroupedBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? themeManager.currentTheme.accentColor : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var thumbnailView: some View {
        ZStack {
            Color.secondary.opacity(0.12)
            if let image = historyVM.thumbnailCache[videoId] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Image(systemName: "video.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            historyVM.loadThumbnail(for: videoId)
        }
    }
}
