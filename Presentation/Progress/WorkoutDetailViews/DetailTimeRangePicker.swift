//
//  DetailTimeRangePicker.swift
//  Agil10.0
//
//  Created by Christiane Roth on 04.06.26.
//


//
//  DetailTimeRangePicker.swift
//  Agil
//
//  Zeitraum-Picker Apple-Health-Style für DetailViews.
//  Extrahiert aus FeedbackDetailView + WeightDetailView (kein Duplikat).
//

import SwiftUI
import AgilCore

struct DetailTimeRangePicker: View {
    @Binding var mode: TimeRangeMode
    @Binding var offset: Int
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 0) {
            Button {
                offset -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(themeManager.currentTheme.accentColor)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            // Mode Tabs
            HStack(spacing: 0) {
                ForEach(TimeRangeMode.allCases, id: \.self) { m in
                    Button {
                        if mode != m { mode = m; offset = 0 }
                    } label: {
                        Text(m.displayName)
                            .font(.subheadline.weight(mode == m ? .semibold : .regular))
                            .foregroundStyle(mode == m ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                mode == m
                                ? RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(.tertiarySystemGroupedBackground))
                                : nil
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button {
                offset += 1
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        mode.canGoForward(offset: offset)
                        ? themeManager.currentTheme.accentColor
                        : Color.secondary.opacity(0.3)
                    )
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(!mode.canGoForward(offset: offset))
        }
    }
}
