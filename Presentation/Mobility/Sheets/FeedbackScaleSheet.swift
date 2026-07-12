
import SwiftUI
import AgilCore


struct FeedbackScaleSheet: View {

    /// Wird mit dem gewählten Wert (0.0–1.0) aufgerufen.
    let onSubmit: (Double) -> Void

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var themeManager: ThemeManager

    /// Aktuelle Position auf der Leiste. nil = noch nichts gewählt.
    @State private var value: Double?

    private let barHeight: CGFloat = 56

    var body: some View {
        VStack(spacing: 28) {
            Text("Wie fühlst du dich jetzt?")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.top, 32)

            scaleBar
                .padding(.horizontal, 24)

            Button {
                if let value { onSubmit(value); dismiss() }
            } label: {
                Text("Fertig")
                    .fontWeight(.semibold)
                                       .frame(maxWidth: .infinity)
                                       .padding()
                                       .background(
                                                               (value == nil ? Color.gray.opacity(0.3)
                                                                              : themeManager.currentTheme.accentColor),
                                                               in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                           )
                                       .foregroundStyle(.white)
                 //   .cornerRadius(12)
            }
            .disabled(value == nil)
            .padding(.horizontal, 24)

            Spacer()
        }
        .presentationDetents([.height(280)])
               .presentationBackground(.ultraThinMaterial)
               .interactiveDismissDisabled()
    }

    // MARK: - Scale Bar

    private var scaleBar: some View {
        GeometryReader { geo in
            let width = geo.size.width

            ZStack(alignment: .leading) {
                // Farbverlauf grün → gelb → rot
                Capsule()
                    .fill(LinearGradient(
                        colors: FeedbackScaleMini.gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                ))

                // Indikator — vertikale Linie
                                if let value {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(.white)
                                        .frame(width: 4, height: barHeight + 12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                                .strokeBorder(.black.opacity(0.15), lineWidth: 0.5)
                                        )
                                        .shadow(radius: 3)
                                        .offset(x: clampedOffset(for: value, in: width))
                                }
            }
            .frame(height: barHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                                            guard width > 0 else { return }
                                            value = min(1.0, max(0.0, g.location.x / width))
                                        }
            )
        }
        .frame(height: barHeight + 12)
    }

    /// Hält den Indikator-Kreis innerhalb der Leiste.
    /// Hält den Indikator innerhalb der Leiste.
        private func clampedOffset(for value: Double, in width: CGFloat) -> CGFloat {
            let knob: CGFloat = 4
            let usable = max(0, width - knob)
            let safeValue = min(1, max(0, value))
            return CGFloat(safeValue) * usable
        }
}

#Preview("FeedbackScaleSheet") {
    FeedbackScaleSheet { print("Wert: \($0)") }
        .frame(width: 390, height: 280)
        .environmentObject(ThemeManager())
}
