//
//  ExpertModeView.swift
//  Agil
//

import SwiftUI

struct ExpertModeView: View {
    @StateObject private var viewModel: ExpertModeViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(
        video: Video,
        tempoProtocol: TempoProtocol,
        weightKg: Int = 5,
        lastTrainingTotalKg: Int? = nil
    ) {
        _viewModel = StateObject(wrappedValue: ExpertModeViewModel(
            videoTitle: video.title,
            tempoProtocol: tempoProtocol,
            weightKg: weightKg,
            lastTrainingTotalKg: lastTrainingTotalKg
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                topInfoRow
                totalBlock
                pillSection
                bottomInfoRow
                
                if viewModel.isInRest {
                    restCard
                }
                
                primaryButton
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.body.weight(.semibold))
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(viewModel.videoTitle).font(.headline)
                }
            }
        }
    }
    
    // MARK: - Top Info Row
    
    private var topInfoRow: some View {
        HStack(alignment: .top) {
            if let last = viewModel.lastTrainingTotalKg {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Letztes Training")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(last) kg")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Modus")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(viewModel.modus.displayName)
                    .font(.headline)
            }
        }
    }
    
    // MARK: - Total Block
    
    private var totalBlock: some View {
        VStack(spacing: 4) {
            Text("GESAMT")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(viewModel.totalWeightKg)")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("kg")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Text(viewModel.plusWeightText)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .opacity(viewModel.showPlusPopup ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: viewModel.showPlusPopup)
                .frame(height: 22)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
    
    // MARK: - Pill Section
    
    private var pillSection: some View {
        // Wrapper: lässt den Langbalken seitlich über die Pille hinausragen
        ZStack {
            pillView
                .frame(width: 140, height: 360)
            
            // Langbalken separat über die Pille gelegt — damit er überstehen kann
            if viewModel.isLongBarVisible {
                GeometryReader { geo in
                    let height: CGFloat = 360
                    let y = height * CGFloat(1 - viewModel.longBarPosition)
                    
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor)
                            .frame(width: 220, height: 22)
                            .shadow(color: Color.accentColor.opacity(0.6), radius: 14)
                            .shadow(color: Color.accentColor.opacity(0.35), radius: 28)
                            .offset(y: y - height / 2)
                            .animation(.linear(duration: 0.08), value: y)
                        Spacer()
                    }
                    .frame(height: height)
                }
                .frame(width: 220, height: 360)
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 360)
    }
    
    private var pillView: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let cornerRadius = width / 2
            let fixedMarkerY = height * (1 - 0.85)
            
            ZStack(alignment: .bottom) {
                // Hintergrund-Pille
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
                
                // Wachsende Kugel/Säule
                ballShape(availableHeight: height)
                    .padding(.bottom, 8)
                
                // Wdh-Label unten in der Kugel/Säule
                Text("\(viewModel.currentRepDisplay) / \(viewModel.totalReps)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 20)
                
                // Fixer Marker
                Rectangle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(height: 3)
                    .padding(.horizontal, -6)
                    .position(x: width / 2, y: fixedMarkerY)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
    
    // Kugel die zur Säule wird — Breite bleibt 60, Höhe wächst mit Wdh
    private func ballShape(availableHeight: CGFloat) -> some View {
        let ballWidth: CGFloat = 60
        let minHeight: CGFloat = 60
        let maxHeight = availableHeight - 16
        let currentHeight = minHeight + CGFloat(viewModel.ballFillRatio) * (maxHeight - minHeight)
        let corner = ballWidth / 2
        
        return RoundedRectangle(cornerRadius: corner)
            .fill(Color.accentColor.opacity(0.35))
            .frame(width: ballWidth, height: currentHeight)
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: currentHeight)
    }
    
    // MARK: - Bottom Info Row
    
    private var bottomInfoRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gewicht")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.weightKg) kg")
                    .font(.headline)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Satz")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.currentSetDisplay) von \(viewModel.totalSets)")
                    .font(.subheadline.weight(.medium))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Phase")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(viewModel.phaseShortLabel)
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .overlay(
            Rectangle()
                .fill(Color(.separator).opacity(0.5))
                .frame(height: 0.5),
            alignment: .top
        )
    }
    
    // MARK: - Rest Card
    
    private var restCard: some View {
        VStack(spacing: 4) {
            Text("Pause")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(viewModel.restSecondsDisplay)s")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Primary Button
    
    private var primaryButton: some View {
        Button {
            if case .done = viewModel.state {
                dismiss()
            } else {
                viewModel.onPrimaryButtonTapped()
            }
        } label: {
            Text(viewModel.primaryButtonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Preview

#Preview("ExpertModeView") {
    let video = Video(
        title: "Bizeps-Curls",
        videoFileName: "curls.mov",
        category: .strength,
        bodyRegion: .fullBody,
        equipment: .noEquipment,
        durationSeconds: 60,
        defaultRepetitions: 12,
        defaultPauseSeconds: 60,
        loopDurationSeconds: 60,
        rating: 0
    )
    let protocolModel = TempoProtocol(
        concentricSec: 2,
        holdSec: 0,
        eccentricSec: 3,
        sets: 3,
        reps: 12,
        restBetweenSetsSec: 60,
        subtype: .dynamic
    )
    
    return ExpertModeView(
        video: video,
        tempoProtocol: protocolModel,
        weightKg: 5,
        lastTrainingTotalKg: 180
    )
}
