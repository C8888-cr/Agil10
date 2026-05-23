//
//  ExpertModeContent.swift
//  Agil
//
/*
import SwiftUI

struct ExpertModeContent: View {
    @ObservedObject var viewModel: ExpertModeViewModel
    @EnvironmentObject var themeManager: ThemeManager
    var onDismiss: () -> Void

    init(viewModel: ExpertModeViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        GeometryReader { geo in
            // ✅ Proportionale Pill-Größe
            let availableHeight = geo.size.height
            let pillHeight = availableHeight * 0.55      // ~55% der Höhe
            let pillWidth = pillHeight * 0.42            // schmal-ovale Form
            let longBarWidth = pillWidth * 2.0      // breiter als Pill

            VStack(spacing: 0) {
                // 1️⃣ TOP: GESAMT + große Zahl
                totalBlock
                    .padding(.top, 8)

                Spacer(minLength: 12)

                // 2️⃣ MITTE: Pill (mit optionalem Pause-Overlay)
                ZStack {
                    pillSection(
                        pillWidth: pillWidth,
                        pillHeight: pillHeight,
                        longBarWidth: longBarWidth
                    )

                    if viewModel.isInRest {
                        restOverlay
                            .frame(maxWidth: pillWidth * 1.8)
                            .transition(
                                .scale(scale: 0.9)
                                .combined(with: .opacity)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.isInRest)

                Spacer(minLength: 12)

                // 3️⃣ UNTEN: Info Row + Button
                VStack(spacing: 12) {
                    bottomInfoRow
                    primaryButton
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Total Block

    private var totalBlock: some View {
        VStack(spacing: 4) {
            Text("GESAMT")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1.2)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(viewModel.totalWeightKg)")
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("kg")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            PlusWeightFloater(
                text: viewModel.plusWeightText,
                isVisible: viewModel.showPlusPopup
            )
            .frame(height: 22)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pill Section

    private func pillSection(pillWidth: CGFloat, pillHeight: CGFloat, longBarWidth: CGFloat) -> some View {
        ZStack {
            pillView
                .frame(width: pillWidth, height: pillHeight)

            if viewModel.isLongBarVisible {
                longBar(width: longBarWidth, pillHeight: pillHeight)
            }
        }
    }

    private func longBar(width: CGFloat, pillHeight: CGFloat) -> some View {
        let yPos = pillHeight * CGFloat(1 - viewModel.longBarPosition)

        return RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.accentColor.opacity(0.7),
                        themeManager.currentTheme.accentColor,
                        themeManager.currentTheme.accentColor.opacity(0.7),
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
                // Glass-Basis
                pillShape
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: pillShape)

                // Tönung für mehr Tiefe
                pillShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Highlight-Kante
                pillShape
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.7),
                                .white.opacity(0.15),
                                .white.opacity(0.05),
                                .white.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )

                // Inhalt
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
        
        @State private var squashX: CGFloat = 1.0    // horizontale Skalierung
        @State private var squashY: CGFloat = 1.0    // vertikale Skalierung
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
                .shadow(color:  themeManager.currentTheme.accentColor.opacity(0.4), radius: 12)
                .animation(.spring(response: 0.55, dampingFraction: 0.55), value: ballHeight)
                .onChange(of: fillRatio) { _, _ in
                    triggerBounce()
                }
        }
        
        private func triggerBounce() {
            // Phase 1: Squash — kurz breiter und niedriger werden
            withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
                squashX = 1.12
                squashY = 0.92
            }
            
            // Phase 2: zurück zur Normalform mit Federn
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                    squashX = 1.0
                    squashY = 1.0
                }
            }
        }
    }
   
    // MARK: - 🆕 Pause Overlay (Liquid Glass)

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
                shape
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: shape)

                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.7),
                                .white.opacity(0.15),
                                .white.opacity(0.05),
                                .white.opacity(0.3)
                            ],
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

    private var bottomInfoRow: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gewicht")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.weightKg) kg")
                    .font(.headline)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .center, spacing: 2) {
                Text("Satz")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.currentSetDisplay) von \(viewModel.totalSets)")
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .trailing, spacing: 2) {
                Text("Phase")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(viewModel.phaseShortLabel)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 4)
        .overlay(
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(height: 0.5),
            alignment: .top
        )
        .padding(.top, 8)
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
                .shadow(color: themeManager.currentTheme.accentColor.opacity(0.6), radius: 6)   // ← Glow während des Aufstiegs
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
            // Reset auf Startposition
            yOffset = 0
            opacity = 0
            scale = 0.85
            
            // Phase 1: schnell einblenden + leicht aufblühen (0.15s)
            withAnimation(.easeOut(duration: 0.15)) {
                opacity = 1.0
                scale = 1.0
            }
            
            // Phase 2: langsam nach oben fließen + ausfaden (0.85s)
            withAnimation(.easeIn(duration: 0.85).delay(0.15)) {
                yOffset = -38       // ← wandert in Richtung GESAMT-Zahl
                opacity = 0
                scale = 0.9
            }
        }
    }
}
*/
//
//  ExpertModeContent.swift
//  Agil
//

import SwiftUI

struct ExpertModeContent: View {
    @ObservedObject var viewModel: ExpertModeViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var onDismiss: () -> Void

    init(viewModel: ExpertModeViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    /// Querformat = compact height.
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    // MARK: - 🎛 Stellschrauben (Layout-Definition)
    //
    // Pillen-Urzustände, getrennt nach Orientierung und Video-Zustand.
    // Der Verschiebe-Slider verändert nur die Live-Werte (mit Video),
    // nicht diese Defaults.
    private enum Tuning {

        // ── HOCHFORMAT ──
        // Mit Video: Pille seitlich rechts.
        static let portraitPillHeightWithVideo: CGFloat = 0.46
        static let portraitPillWidthWithVideo: CGFloat = 0.42
        static let portraitPillXWithVideo: CGFloat = 0.70
        static let portraitPillYWithVideo: CGFloat = 0.62
        // Ohne Video: Pille mittig, groß, weiter oben.
        static let portraitPillHeightNoVideo: CGFloat = 0.60
        static let portraitPillWidthNoVideo: CGFloat = 0.42
        static let portraitPillXNoVideo: CGFloat = 0.50
        static let portraitPillYNoVideo: CGFloat = 0.48

      
        
        // ── QUERFORMAT ──
        // Quer ist der Bildschirm niedrig → Pille muss prozentual
        // deutlich höher sein, um nicht winzig zu wirken.
        static let landscapePillHeightWithVideo: CGFloat = 0.78
        static let landscapePillWidthWithVideo: CGFloat = 0.42
        static let landscapePillXWithVideo: CGFloat = 0.78
        static let landscapePillYWithVideo: CGFloat = 0.52
        static let landscapePillHeightNoVideo: CGFloat = 0.62
        static let landscapePillWidthNoVideo: CGFloat = 0.48
        static let landscapePillXNoVideo: CGFloat = 0.50
        static let landscapePillYNoVideo: CGFloat = 0.46

        // ── Long-Bar (Hoch/Runter-Linie) ──
        // Breite als Faktor der Pillenbreite.
        // Ohne Video darf die Linie schön weit rausragen,
        // mit Video wird sie gekürzt (stört sonst im Bild).
        static let longBarFactorNoVideo: CGFloat = 2.0
        static let longBarFactorWithVideo: CGFloat = 1.25

        // ── Sonstiges ──
        static let bottomGradientHeightRatio: CGFloat = 0.42
        static let topBarTopPadding: CGFloat = 8
    }

    /// Ob der Video-Hintergrund aktuell sichtbar ist.
    private var showsVideo: Bool {
        viewModel.isVideoFeatureEnabled && viewModel.isVideoVisible
    }

    // MARK: - Verschiebe-Slider (Live-Anpassung, nur mit Video)
    //
    // Starten beim jeweiligen Urzustand "mit Video". Werden nicht
    // gespeichert — beim nächsten Start gilt wieder der Urzustand.
    @State private var livePillHeight: CGFloat = Tuning.portraitPillHeightWithVideo
    @State private var livePillWidth: CGFloat = Tuning.portraitPillWidthWithVideo
    @State private var livePillX: CGFloat = Tuning.portraitPillXWithVideo
    @State private var livePillY: CGFloat = Tuning.portraitPillYWithVideo
    @State private var showAdjustPanel: Bool = false
    /// Merkt sich, ob die Live-Werte schon zur aktuellen Orientierung passen.
    @State private var liveValuesOrientationIsLandscape: Bool = false

    // Effektive Pillen-Parameter — abhängig von Orientierung + Video.
    private var pillHeightRatio: CGFloat {
        if showsVideo { return livePillHeight }
        return isLandscape ? Tuning.landscapePillHeightNoVideo : Tuning.portraitPillHeightNoVideo
    }
    private var pillWidthRatio: CGFloat {
        if showsVideo { return livePillWidth }
        return isLandscape ? Tuning.landscapePillWidthNoVideo : Tuning.portraitPillWidthNoVideo
    }
    private var pillCenterX: CGFloat {
        if showsVideo { return livePillX }
        return isLandscape ? Tuning.landscapePillXNoVideo : Tuning.portraitPillXNoVideo
    }
    private var pillCenterY: CGFloat {
        if showsVideo { return livePillY }
        return isLandscape ? Tuning.landscapePillYNoVideo : Tuning.portraitPillYNoVideo
    }

    /// Urzustand "mit Video" für die aktuelle Orientierung.
    private func withVideoDefaults() -> (h: CGFloat, w: CGFloat, x: CGFloat, y: CGFloat) {
        if isLandscape {
            return (Tuning.landscapePillHeightWithVideo,
                    Tuning.landscapePillWidthWithVideo,
                    Tuning.landscapePillXWithVideo,
                    Tuning.landscapePillYWithVideo)
        } else {
            return (Tuning.portraitPillHeightWithVideo,
                    Tuning.portraitPillWidthWithVideo,
                    Tuning.portraitPillXWithVideo,
                    Tuning.portraitPillYWithVideo)
        }
    }

    /// Setzt die Live-Werte auf den Urzustand der aktuellen Orientierung.
    private func resetLiveValues() {
        let d = withVideoDefaults()
        livePillHeight = d.h
        livePillWidth = d.w
        livePillX = d.x
        livePillY = d.y
        liveValuesOrientationIsLandscape = isLandscape
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                backgroundLayer
                bottomGradient(in: size)
                pillCluster(in: size)

                if viewModel.isInRest {
                    restOverlay
                        .frame(maxWidth: size.width * 0.8)
                        .position(x: size.width / 2, y: size.height * pillCenterY)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }

                bottomControls
                topBar

                if showsVideo && showAdjustPanel {
                    adjustPanel(in: size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: showsVideo)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.isInRest)
            // Dreht der Nutzer das Gerät, passen die Live-Werte nicht
            // mehr → auf den Urzustand der neuen Orientierung setzen.
            .onChange(of: isLandscape) { _, newValue in
                if newValue != liveValuesOrientationIsLandscape {
                    resetLiveValues()
                }
            }
            .onAppear {
                            if liveValuesOrientationIsLandscape != isLandscape {
                                resetLiveValues()
                            }
                        }
                        .task {
                            await viewModel.detectVideoOrientation()
                        }
        }
    }

    // MARK: - Background Layer

    @ViewBuilder
    private var backgroundLayer: some View {
        if showsVideo {
            ExpertVideoLoopPlayer(
                video: viewModel.video,
                isPlaying: viewModel.isVideoPlaying
            )
            .ignoresSafeArea()
        } else {
            Color.black
                .ignoresSafeArea()
        }
    }

    // MARK: - Bottom Gradient

    private func bottomGradient(in size: CGSize) -> some View {
        VStack {
            Spacer()
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.55),
                    .black.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: size.height * Tuning.bottomGradientHeightRatio)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Top Bar (Pfeil zurück + Slider-Icon + Video-Button)

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

                HStack(spacing: 10) {
                    // Verschiebe-Panel öffnen — nur sinnvoll mit Video.
                    if viewModel.canToggleVideo && showsVideo {
                        Button {
                            showAdjustPanel.toggle()
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .accessibilityLabel("Pille anpassen")
                    }

                    // Video ein-/ausblenden.
                    if viewModel.canToggleVideo {
                        Button {
                            viewModel.toggleVideo()
                            if !viewModel.isVideoVisible {
                                showAdjustPanel = false
                            }
                        } label: {
                            Image(systemName: showsVideo ? "video.fill" : "video.slash.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .accessibilityLabel(showsVideo ? "Video ausblenden" : "Video einblenden")
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, Tuning.topBarTopPadding)
    }

    // MARK: - Pill Cluster (Pille + kg-Anzeige wandern gemeinsam)

    private func pillCluster(in size: CGSize) -> some View {
        let pillHeight = size.height * pillHeightRatio
        let pillWidth = pillHeight * pillWidthRatio

        // Long-Bar: ohne Video lang, mit Video gekürzt.
        let longBarFactor = showsVideo
            ? Tuning.longBarFactorWithVideo
            : Tuning.longBarFactorNoVideo
        let longBarWidth = pillWidth * longBarFactor

        let centerX = size.width * pillCenterX
        let centerY = size.height * pillCenterY

        return VStack(spacing: 6) {
            totalBlock

            // Pille zuerst, Long-Bar danach → Long-Bar liegt VOR der Pille.
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
                        themeManager.currentTheme.accentColor.opacity(0.7),
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
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                pillShape
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.7),
                                .white.opacity(0.15),
                                .white.opacity(0.05),
                                .white.opacity(0.3)
                            ],
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

    // MARK: - Pause Overlay (Liquid Glass)

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
                shape
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: shape)

                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.7),
                                .white.opacity(0.15),
                                .white.opacity(0.05),
                                .white.opacity(0.3)
                            ],
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

    // MARK: - Bottom Controls (Info Row + Button)

    private var bottomControls: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                bottomInfoRow
            //    primaryButton
            }
            .padding(.horizontal)
        }
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
    }

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

    // MARK: - Verschiebe-Panel (Pille anpassen)

    private func adjustPanel(in size: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        // Querformat: kompakter (schmaler, weniger Abstand nach unten).
        let panelMaxWidth: CGFloat = isLandscape ? 360 : .infinity
        let panelBottomPadding: CGFloat = isLandscape ? 84 : 140

        return VStack {
            Spacer()
            VStack(alignment: .leading, spacing: isLandscape ? 6 : 10) {
                HStack {
                    Text("Pille anpassen")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Zurücksetzen") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            resetLiveValues()
                        }
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(themeManager.currentTheme.accentColor)
                }

                adjustSlider("Größe",  value: $livePillHeight, range: 0.30...0.90)
                adjustSlider("Breite", value: $livePillWidth,  range: 0.30...0.60)
                adjustSlider("Links/Rechts", value: $livePillX, range: 0.25...0.85)
                adjustSlider("Hoch/Runter",  value: $livePillY, range: 0.25...0.75)
            }
            .padding(isLandscape ? 12 : 16)
            .frame(maxWidth: panelMaxWidth)
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(.black.opacity(0.35))
                    shape.stroke(.white.opacity(0.15), lineWidth: 1)
                }
            }
            .clipShape(shape)
            .padding(.horizontal)
            .padding(.bottom, panelBottomPadding)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func adjustSlider(_ label: String,
                              value: Binding<CGFloat>,
                              range: ClosedRange<CGFloat>) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 90, alignment: .leading)
            Slider(value: value, in: range)
                .tint(themeManager.currentTheme.accentColor)
        }
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
