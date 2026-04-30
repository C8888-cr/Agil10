//
//  ExpertModeContent.swift
//  Agil
//

import SwiftUI

struct ExpertModeContent: View {
    @ObservedObject var viewModel: ExpertModeViewModel
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
                        Color.accentColor.opacity(0.7),
                        Color.accentColor,
                        Color.accentColor.opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: 16)
            .shadow(color: Color.accentColor.opacity(0.8), radius: 14)
            .shadow(color: Color.accentColor.opacity(0.5), radius: 28)
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
                            Color.accentColor.opacity(0.5),
                            Color.accentColor.opacity(0.85),
                            Color.accentColor.opacity(0.45)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: ballWidth, height: ballHeight)
                .scaleEffect(x: squashX, y: squashY, anchor: .bottom)
                .shadow(color: Color.accentColor.opacity(0.4), radius: 12)
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
        
        var body: some View {
            Text(text)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .shadow(color: Color.accentColor.opacity(0.6), radius: 6)   // ← Glow während des Aufstiegs
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
