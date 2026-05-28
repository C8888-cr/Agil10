//
//  FeedbackScaleMini.swift
//  Agil10.0
//
//  Created by Christiane Roth on 28.05.26.
//


import SwiftUI

/// Kompakte, nicht-interaktive Anzeige der Feedback-Skala.
/// Zeigt mit einer vertikalen Linie, wo der gespeicherte Wert liegt.
struct FeedbackScaleMini: View {

    /// Position auf der Skala (0.0–1.0).
    let value: Double

    var width: CGFloat = 64
    var height: CGFloat = 10

    /// Der Farbverlauf der Feedback-Skala — eine Quelle für Sheet und Card.
    static let gradientColors: [Color] = [.red, .orange, .yellow, .green]

    var body: some View {
        GeometryReader { geo in
            let usable = max(0, geo.size.width - markerWidth)
            let safeValue = min(1, max(0, value))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(
                        colors: Self.gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ))

                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(.white)
                    .frame(width: markerWidth, height: geo.size.height + 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 1, style: .continuous)
                            .strokeBorder(.black.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(radius: 1.5)
                    .offset(x: CGFloat(safeValue) * usable)
            }
        }
        .frame(width: width, height: height)
    }

    private var markerWidth: CGFloat { 3 }
}

#Preview {
    VStack(spacing: 16) {
        FeedbackScaleMini(value: 0.2)
        FeedbackScaleMini(value: 0.5)
        FeedbackScaleMini(value: 0.9)
    }
    .padding()
}