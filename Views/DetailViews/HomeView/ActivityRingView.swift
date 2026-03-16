import SwiftUI

// MARK: - AnimatableModifier
struct RingModifier: AnimatableModifier {
    var trimEnd: Double
    var completedRounds: Int
    var lineWidth: CGFloat
    var color: UIColor

    var animatableData: Double {
        get { trimEnd }
        set { trimEnd = newValue }
    }

    func body(content: Content) -> some View {
        content.overlay(
            RingCanvas(
                trimEnd: trimEnd,
                completedRounds: completedRounds,
                lineWidth: lineWidth,
                color: color
            )
        )
    }
}

// MARK: - ActivityRingView
struct ActivityRingView: View {
    let progress: Double

    @State private var trimEnd: Double = 0
    @State private var completedRounds: Int = 0
    @State private var animationID: UUID = UUID()
    @State private var hasAppeared: Bool = false

    private let lineWidth: CGFloat = 8
    private let frameSize: CGFloat = 60
    private let mainColor = UIColor(Color(hex: "#E20074"))

    var body: some View {
        Color.clear
            .frame(width: frameSize, height: frameSize)
            .modifier(RingModifier(
                trimEnd: trimEnd,
                completedRounds: completedRounds,
                lineWidth: lineWidth,
                color: mainColor
            ))
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                runAnimation(to: progress)
            }
            .onChange(of: progress) { _, newValue in
                runAnimation(to: newValue)
            }
    }

    private func runAnimation(to target: Double) {
        let id = UUID()
        animationID = id
        let currentTotal = Double(completedRounds) + trimEnd
        withAnimation(.none) {
            trimEnd = currentTotal - Double(completedRounds)
        }
        let targetRounds = Int(target)
        let targetFraction = target - Double(targetRounds)
        if target >= currentTotal {
            animateForward(toRounds: targetRounds, toFraction: targetFraction, id: id)
        } else {
            animateBackward(toRounds: targetRounds, toFraction: targetFraction, id: id)
        }
    }

    private func animateForward(toRounds: Int, toFraction: Double, id: UUID) {
        guard id == animationID else { return }
        if completedRounds == toRounds {
            let d = duration(from: trimEnd, to: toFraction)
            withAnimation(.easeInOut(duration: d)) { trimEnd = toFraction }
        } else {
            let currentTrim = trimEnd
            let d = duration(from: currentTrim, to: 1.0)
            withAnimation(.easeInOut(duration: d)) { trimEnd = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                guard id == self.animationID else { return }
                self.completedRounds += 1
                self.trimEnd = 0.0
                self.animateForward(toRounds: toRounds, toFraction: toFraction, id: id)
            }
        }
    }

    private func animateBackward(toRounds: Int, toFraction: Double, id: UUID) {
        guard id == animationID else { return }
        if completedRounds == toRounds {
            let d = duration(from: trimEnd, to: toFraction)
            withAnimation(.easeInOut(duration: d)) { trimEnd = toFraction }
        } else {
            let currentTrim = trimEnd
            let d = duration(from: currentTrim, to: 0.0)
            withAnimation(.easeInOut(duration: d)) { trimEnd = 0.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                guard id == self.animationID else { return }
                self.completedRounds -= 1
                self.trimEnd = 1.0
                self.animateBackward(toRounds: toRounds, toFraction: toFraction, id: id)
            }
        }
    }

    private func duration(from: Double, to: Double) -> Double {
        let distance = abs(to - from)
        return min(max(distance * 0.8, 0.3), 0.7)
    }
}

// MARK: - RingCanvas
struct RingCanvas: UIViewRepresentable {
    var trimEnd: Double
    var completedRounds: Int
    var lineWidth: CGFloat
    var color: UIColor

    func makeUIView(context: Context) -> RingCanvasView {
        let view = RingCanvasView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: RingCanvasView, context: Context) {
        uiView.trimEnd = trimEnd
        uiView.completedRounds = completedRounds
        uiView.lineWidth = lineWidth
        uiView.color = color
        uiView.setNeedsDisplay()
    }
}

// MARK: - RingCanvasView
class RingCanvasView: UIView {
    var trimEnd: Double = 0
    var completedRounds: Int = 0
    var lineWidth: CGFloat = 8
    var color: UIColor = UIColor(Color(hex: "#E20074"))

    var progress: Double { Double(completedRounds) + trimEnd }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let cx = rect.midX
        let cy = rect.midY
        let r = (rect.width / 2) - (lineWidth / 2)
        let lw = lineWidth
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + CGFloat(trimEnd) * .pi * 2

        // 1. Track
        ctx.setLineWidth(lw)
        ctx.setStrokeColor(color.withAlphaComponent(0.15).cgColor)
        ctx.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                   startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()

        // 2. Hintergrundring
        if completedRounds >= 1 {
            ctx.setLineWidth(lw)
            ctx.setStrokeColor(color.cgColor)
            ctx.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                       startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.strokePath()
        }

        // 3. Aktiver Bogen
        if trimEnd > 0.001 {
            ctx.setLineWidth(lw)
            ctx.setLineCap(.round)
            ctx.setStrokeColor(color.cgColor)
            ctx.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                       startAngle: startAngle, endAngle: endAngle, clockwise: false)
            ctx.strokePath()

            // 4. Schatten in Hintergrundfarbe — nur ab Spitze in UZS
            if completedRounds >= 1 {
                // systemBackground Farbe auslesen (Light/Dark Mode automatisch)
                let bgColor = UIColor.systemBackground
                var sr: CGFloat = 1, sg: CGFloat = 1, sb: CGFloat = 1, sa: CGFloat = 1
                bgColor.getRed(&sr, green: &sg, blue: &sb, alpha: &sa)

                ctx.saveGState()

                // Clip: nur Donut-Streifen
                ctx.beginPath()
                ctx.addArc(center: CGPoint(x: cx, y: cy), radius: r + lw / 2,
                           startAngle: 0, endAngle: .pi * 2, clockwise: false)
                ctx.addArc(center: CGPoint(x: cx, y: cy), radius: r - lw / 2,
                           startAngle: 0, endAngle: .pi * 2, clockwise: true)
                ctx.clip(using: .evenOdd)

                // Schatten-Bögen ab Spitze in UZS, von opak nach transparent
                let shadowLen: CGFloat = 0.6
                let steps = 20
                for i in 0..<steps {
                    let t = CGFloat(i) / CGFloat(steps)
                    let segStart = endAngle + t * shadowLen
                    let segEnd = endAngle + (t + 1 / CGFloat(steps)) * shadowLen
                    let opacity = pow(1 - t, 1.5) * 0.92

                    ctx.setLineWidth(lw)
                    ctx.setLineCap(.butt)
                    ctx.setStrokeColor(UIColor(red: sr, green: sg, blue: sb,
                                               alpha: opacity).cgColor)
                    ctx.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                               startAngle: segStart, endAngle: segEnd, clockwise: false)
                    ctx.strokePath()
                }

                ctx.restoreGState()

                // Spitze sauber drüber
                ctx.setLineWidth(lw)
                ctx.setLineCap(.round)
                ctx.setStrokeColor(color.cgColor)
                ctx.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                           startAngle: endAngle - 0.12, endAngle: endAngle, clockwise: false)
                ctx.strokePath()
            }
        }

        // 5. Prozent Text
        let pct = "\(Int(progress * 100))%"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: color
        ]
        let size = (pct as NSString).size(withAttributes: attrs)
        (pct as NSString).draw(
            at: CGPoint(x: cx - size.width / 2, y: cy - size.height / 2),
            withAttributes: attrs
        )
    }
}
