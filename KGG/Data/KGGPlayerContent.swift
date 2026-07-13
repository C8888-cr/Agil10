//
//  KGGPlayerContent.swift
//  Agil
//
//  Player-UI für den KGG-Modus. Optisch an ExpertModeContent angelehnt,
//  aber ohne Video-Toggle und ohne Tuning-Panel (Video-Sichtbarkeit ist
//  read-only und wird von KGGExerciseListView vorgegeben).
//

import SwiftUI
import AgilCore

struct KGGPlayerContent: View {
    @ObservedObject var viewModel: KGGExercisePlayerViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var onDismiss: () -> Void

    init(viewModel: KGGExercisePlayerViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    /// Video-Sichtbarkeit ist fest vorgegeben (kein Toggle im KGG-Modus).
    private var showsVideo: Bool {
        viewModel.isVideoVisible
    }

    private var usesSplitLayout: Bool {
        guard showsVideo else { return false }
        let videoPortrait = viewModel.isPortraitVideo
        let devicePortrait = !isLandscape
        return videoPortrait != devicePortrait
    }

    private var splitIsVertical: Bool {
        !viewModel.isPortraitVideo
    }

    // MARK: - Tuning (feste Werte, kein Live-Anpassen im KGG-Modus)

    private enum Tuning {
        static let portraitPillHeightWithVideo: CGFloat = 0.46
        static let portraitPillWidthWithVideo: CGFloat = 0.42
        static let portraitPillXWithVideo: CGFloat = 0.70
        static let portraitPillYWithVideo: CGFloat = 0.62
        static let portraitPillHeightNoVideo: CGFloat = 0.60
        static let portraitPillWidthNoVideo: CGFloat = 0.42
        static let portraitPillXNoVideo: CGFloat = 0.50
        static let portraitPillYNoVideo: CGFloat = 0.48

        static let landscapePillHeightWithVideo: CGFloat = 0.78
        static let landscapePillWidthWithVideo: CGFloat = 0.42
        static let landscapePillXWithVideo: CGFloat = 0.78
        static let landscapePillYWithVideo: CGFloat = 0.52
        static let landscapePillHeightNoVideo: CGFloat = 0.62
        static let landscapePillWidthNoVideo: CGFloat = 0.48
        static let landscapePillXNoVideo: CGFloat = 0.50
        static let landscapePillYNoVideo: CGFloat = 0.46

        static let splitVideoRatio: CGFloat = 0.60

        static let splitVertPillHeight: CGFloat = 0.80
        static let splitVertPillWidth: CGFloat = 0.42
        static let splitVertPillX: CGFloat = 0.50
        static let splitVertPillY: CGFloat = 0.20

        static let splitHorizPillHeight: CGFloat = 0.66
        static let splitHorizPillWidth: CGFloat = 0.42
        static let splitHorizPillX: CGFloat = 0.44
        static let splitHorizPillY: CGFloat = 0.54

        static let cardCornerRadius: CGFloat = 22
        static let cardPadding: CGFloat = 12

        static let longBarFactorNoVideo: CGFloat = 2.0
        static let longBarFactorWithVideo: CGFloat = 1.25

        static let bottomGradientHeightRatio: CGFloat = 0.42
        static let topBarTopPadding: CGFloat = 8
    }

    private var pillHeightRatio: CGFloat {
        if usesSplitLayout {
            return splitIsVertical ? Tuning.splitVertPillHeight : Tuning.splitHorizPillHeight
        }
        if showsVideo {
            return isLandscape ? Tuning.landscapePillHeightWithVideo : Tuning.portraitPillHeightWithVideo
        }
        return isLandscape ? Tuning.landscapePillHeightNoVideo : Tuning.portraitPillHeightNoVideo
    }
    private var pillWidthRatio: CGFloat {
        if usesSplitLayout {
            return splitIsVertical ? Tuning.splitVertPillWidth : Tuning.splitHorizPillWidth
        }
        if showsVideo {
            return isLandscape ? Tuning.landscapePillWidthWithVideo : Tuning.portraitPillWidthWithVideo
        }
        return isLandscape ? Tuning.landscapePillWidthNoVideo : Tuning.portraitPillWidthNoVideo
    }
    private var pillCenterX: CGFloat {
        if usesSplitLayout {
            return splitIsVertical ? Tuning.splitVertPillX : Tuning.splitHorizPillX
        }
        if showsVideo {
            return isLandscape ? Tuning.landscapePillXWithVideo : Tuning.portraitPillXWithVideo
        }
        return isLandscape ? Tuning.landscapePillXNoVideo : Tuning.portraitPillXNoVideo
    }
    private var pillCenterY: CGFloat {
        if usesSplitLayout {
            return splitIsVertical ? Tuning.splitVertPillY : Tuning.splitHorizPillY
        }
        if showsVideo {
            return isLandscape ? Tuning.landscapePillYWithVideo : Tuning.portraitPillYWithVideo
        }
        return isLandscape ? Tuning.landscapePillYNoVideo : Tuning.portraitPillYNoVideo
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                if usesSplitLayout {
                    splitLayout(in: size)
                } else {
                    overlayLayout(in: size)
                }

                bottomControls
                topBar

                if viewModel.isInRest {
                    restOverlay
                        .frame(maxWidth: size.width * 0.8)
                        .position(x: size.width / 2, y: size.height / 2)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: usesSplitLayout)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.isInRest)
            .task {
                await viewModel.detectVideoOrientation()
            }
        }
    }

    // MARK: - Overlay Layout

    private func overlayLayout(in size: CGSize) -> some View {
        ZStack {
            backgroundLayer
            bottomGradient(in: size)
            pillClusterArea(width: size.width, height: size.height)
        }
    }

    // MARK: - Split Layout

    private func splitLayout(in size: CGSize) -> some View {
        Group {
            if splitIsVertical {
                VStack(spacing: 0) {
                    videoCard(width: size.width, height: size.height * Tuning.splitVideoRatio)
                    pillClusterArea(width: size.width, height: size.height * (1 - Tuning.splitVideoRatio))
                }
            } else {
                HStack(spacing: 0) {
                    videoCard(width: size.width * Tuning.splitVideoRatio, height: size.height)
                    pillClusterArea(width: size.width * (1 - Tuning.splitVideoRatio), height: size.height)
                }
            }
        }
    }

    private func videoCard(width: CGFloat, height: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: Tuning.cardCornerRadius, style: .continuous)

        return ExpertVideoLoopPlayer(
            video: viewModel.video,
            isPlaying: viewModel.isVideoPlaying
        )
        .aspectRatio(viewModel.isPortraitVideo ? 9.0/16.0 : 16.0/9.0, contentMode: .fit)
        .clipShape(shape)
        .overlay(shape.stroke(.white.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.6), radius: 16, y: 6)
        .padding(Tuning.cardPadding)
        .frame(width: width, height: height)
    }

    // MARK: - Pill Cluster

    private func pillClusterArea(width: CGFloat, height: CGFloat) -> some View {
        let pillHeight = height * pillHeightRatio
        let pillWidth = pillHeight * pillWidthRatio

        let longBarFactor = showsVideo ? Tuning.longBarFactorWithVideo : Tuning.longBarFactorNoVideo
        let longBarWidth = pillWidth * longBarFactor

        let centerX = width * pillCenterX
        let centerY = height * pillCenterY

        return ZStack {
            VStack(spacing: 6) {
                totalBlock

                ZStack {
                    pillView
                        .frame(width: pillWidth, height: pillHeight)

                    if viewModel.isLongBarVisible {
                        longBar(width: longBarWidth, pillHeight: pillHeight)
                    }
                }
            }
            .frame(width: max(pillWidth, longBarWidth))
            .position(x: centerX, y: centerY)
        }
        .frame(width: width, height: height)
    }

    // MARK: - Background Layer

    @ViewBuilder
    private var backgroundLayer: some View {
        if showsVideo {
            ExpertVideoLoopPlayer(video: viewModel.video, isPlaying: viewModel.isVideoPlaying)
                .ignoresSafeArea()
        } else {
            Color.black.ignoresSafeArea()
        }
    }

    private func bottomGradient(in size: CGSize) -> some View {
        VStack {
            Spacer()
            LinearGradient(
                colors: [.clear, .black.opacity(0.55), .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: size.height * Tuning.bottomGradientHeightRatio)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Top Bar (nur Zurück-Button, kein Video-Toggle)

    private var topBar: some View {
        VStack {
            HStack {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Zurück")

                Spacer()
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, Tuning.topBarTopPadding)
    }

    // MARK: - Total Block

    private var totalBlock: some View {
        VStack(spacing: 2) {
            Text("GESAMT")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .tracking(1.2)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(viewModel.totalWeightKg)")
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("kg")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
            PlusWeightFloater(
                text: viewModel.plusWeightText,
                isVisible: viewModel.showPlusPopup
            )
            .frame(height: 20)
        }
        .shadow(color: .black.opacity(showsVideo ? 0.8 : 0), radius: 8)
    }

    // MARK: - Pill

    private func longBar(width: CGFloat, pillHeight: CGFloat) -> some View {
        let yPos = pillHeight * CGFloat(1 - viewModel.longBarPosition)

        return RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.accentColor.opacity(0.7),
                        themeManager.currentTheme.accentColor,
                        themeManager.currentTheme.accentColor.opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: 16)
            .shadow(color: themeManager.currentTheme.accentColor.opacity(0.8), radius: 14)
            .shadow(color: themeManager.currentTheme.accentColor.opacity(0.5), radius: 28)
            .offset(y: yPos - pillHeight / 2)
            .animation(.linear(duration: 0.08), value: yPos)
            .allowsHitTesting(false)
    }

    private var pillView: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let cornerRadius = width / 2
            let fixedMarkerY = height * (1 - 0.85)
            let pillShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

            ZStack(alignment: .bottom) {
                pillShape
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: pillShape)

                pillShape
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                pillShape
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.7), .white.opacity(0.15), .white.opacity(0.05), .white.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )

                ballShape(availableHeight: height - 30, ballWidth: width * 0.42)
                    .padding(.bottom, 6)

                Text("\(viewModel.currentRepDisplay) / \(viewModel.totalReps)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 16)

                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 2.5)
                    .padding(.horizontal, -6)
                    .position(x: width / 2, y: fixedMarkerY)
            }
            .clipShape(pillShape)
            .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
        }
    }

    private func ballShape(availableHeight: CGFloat, ballWidth: CGFloat) -> some View {
        BouncyBall(
            ballWidth: ballWidth,
            availableHeight: availableHeight,
            fillRatio: viewModel.ballFillRatio
        )
    }

    // MARK: - BouncyBall

    private struct BouncyBall: View {
        let ballWidth: CGFloat
        let availableHeight: CGFloat
        let fillRatio: Double

        @State private var squashX: CGFloat = 1.0
        @State private var squashY: CGFloat = 1.0
        @EnvironmentObject var themeManager: ThemeManager

        private var ballHeight: CGFloat {
            let minHeight = ballWidth
            let maxHeight = availableHeight - 10
            return minHeight + CGFloat(fillRatio) * (maxHeight - minHeight)
        }

        var body: some View {
            RoundedRectangle(cornerRadius: ballWidth / 2)
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.currentTheme.accentColor.opacity(0.5),
                            themeManager.currentTheme.accentColor.opacity(0.85),
                            themeManager.currentTheme.accentColor.opacity(0.45)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: ballWidth, height: ballHeight)
                .scaleEffect(x: squashX, y: squashY, anchor: .bottom)
                .shadow(color: themeManager.currentTheme.accentColor.opacity(0.4), radius: 12)
                .animation(.spring(response: 0.55, dampingFraction: 0.55), value: ballHeight)
                .onChange(of: fillRatio) { _, _ in
                    triggerBounce()
                }
        }

        private func triggerBounce() {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
                squashX = 1.12
                squashY = 0.92
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                    squashX = 1.0
                    squashY = 1.0
                }
            }
        }
    }

    // MARK: - Pause Overlay

    private var restOverlay: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        return VStack(spacing: 8) {
            Text("PAUSE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1.2)

            Text("\(viewModel.restSecondsDisplay)")
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text(" Sekunden ")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("bis Satz \(viewModel.currentSetDisplay)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background {
            ZStack {
                shape.fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: shape)

                shape.fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                shape.stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.7), .white.opacity(0.15), .white.opacity(0.05), .white.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
        }
        .clipShape(shape)
        .shadow(color: .black.opacity(0.6), radius: 30, y: 12)
        .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
    }

    // MARK: - Bottom Info Row

    private var bottomControls: some View {
        VStack(spacing: 12) {
            Spacer()
            bottomInfoRow
            primaryButton
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var bottomInfoRow: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gewicht")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(viewModel.weightKg) kg")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .center, spacing: 2) {
                Text("Satz")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(viewModel.currentSetDisplay) von \(viewModel.totalSets)")
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .trailing, spacing: 2) {
                Text("Phase")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                Text(viewModel.phaseShortLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 4)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 0.5),
            alignment: .top
        )
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Primary Button

    private var primaryButton: some View {
        Button {
            viewModel.onPrimaryButtonTapped()
        } label: {
            Text(viewModel.primaryButtonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.glassProminent)
    }

    // MARK: - PlusWeightFloater

    private struct PlusWeightFloater: View {
        let text: String
        let isVisible: Bool

        @State private var yOffset: CGFloat = 0
        @State private var opacity: Double = 0
        @State private var scale: CGFloat = 1.0
        @EnvironmentObject var themeManager: ThemeManager

        var body: some View {
            Text(text)
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.accentColor)
                .shadow(color: themeManager.currentTheme.accentColor.opacity(0.6), radius: 6)
                .offset(y: yOffset)
                .opacity(opacity)
                .scaleEffect(scale)
                .onChange(of: isVisible) { _, newValue in
                    if newValue {
                        triggerFloat()
                    }
                }
        }

        private func triggerFloat() {
            yOffset = 0
            opacity = 0
            scale = 0.85

            withAnimation(.easeOut(duration: 0.15)) {
                opacity = 1.0
                scale = 1.0
            }

            withAnimation(.easeIn(duration: 0.85).delay(0.15)) {
                yOffset = -38
                opacity = 0
                scale = 0.9
            }
        }
    }
}
