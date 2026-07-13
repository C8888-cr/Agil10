//
//  KGGPatientPrintService.swift
//  AgilKGG
//
//  Erzeugt ein Druck-PDF aus Warmup + Übungen eines Patienten.
//  Reine PDF-Generierung (UIGraphicsPDFRenderer) — keine View-Logik,
//  kein Export/Speichern, wird nur im Speicher erzeugt und direkt
//  an UIPrintInteractionController übergeben.
//

import UIKit
import AgilCore

struct KGGPatientPrintService {

    private let pageSize = CGSize(width: 595.2, height: 841.8) // A4 @ 72dpi
    private let margin: CGFloat = 40
    private let logoSize: CGFloat = 64
    private let nameColumnWidth: CGFloat = 140

    func generatePDF(warmups: [KGGWarmup], exercises: [KGGExercise]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        return renderer.pdfData { context in
            var cursorY: CGFloat = margin
            var isFirstPage = true

            func drawLogo() {
                guard let logo = UIImage(named: "AgilLogo") else { return }
                let rect = CGRect(x: pageSize.width - margin - logoSize, y: margin, width: logoSize, height: logoSize)
                logo.draw(in: rect)
            }

            func startPage() {
                context.beginPage()
                cursorY = margin
                if isFirstPage {
                    drawLogo()
                    cursorY += logoSize + 16
                    isFirstPage = false
                }
            }

            func ensureSpace(_ height: CGFloat) {
                if cursorY + height > pageSize.height - margin {
                    startPage()
                }
            }

            func drawSectionHeader(_ title: String) {
                ensureSpace(24)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                    .foregroundColor: UIColor.darkGray
                ]
                (title.uppercased() as NSString).draw(at: CGPoint(x: margin, y: cursorY), withAttributes: attrs)
                cursorY += 22
            }

            func drawCardBorder(_ rect: CGRect) {
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
                UIColor(white: 0.82, alpha: 1).setStroke()
                path.lineWidth = 0.75
                path.stroke()
            }

            func formattedNumber(_ value: Double) -> String {
                let rounded = value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
                return rounded.replacingOccurrences(of: ".", with: ",")
            }

            func warmupSummary(_ w: KGGWarmup) -> String {
                var parts = ["\(w.duration) Min"]
                if let level = w.level { parts.append("Stufe \(level)") }
                if let seatLevel = w.seatLevel { parts.append("Sitzhöhe Stufe \(seatLevel)") }
                if let speed = w.speedKmh { parts.append("\(formattedNumber(speed)) km/h") }
                if let weight = w.weight { parts.append("\(formattedNumber(weight)) kg") }
                return parts.joined(separator: " · ")
            }

            func drawWarmupCard(_ w: KGGWarmup) {
                let cardHeight: CGFloat = 34
                ensureSpace(cardHeight + 8)
                let rect = CGRect(x: margin, y: cursorY, width: pageSize.width - margin * 2, height: cardHeight)
                drawCardBorder(rect)

                let nameAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                    .foregroundColor: UIColor.black
                ]
                (w.type as NSString).draw(at: CGPoint(x: rect.minX + 10, y: rect.midY - 8), withAttributes: nameAttrs)

                let summaryAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.darkGray
                ]
                let summary = warmupSummary(w) as NSString
                let summarySize = summary.size(withAttributes: summaryAttrs)
                summary.draw(at: CGPoint(x: rect.maxX - 10 - summarySize.width, y: rect.midY - 6), withAttributes: summaryAttrs)

                cursorY += cardHeight + 8
            }

            func exerciseFieldLines(_ e: KGGExercise) -> [String] {
                var lines: [String] = []
                lines.append("Sätze: \(e.sets)")
                lines.append("Wdh: \(e.reps)")
                if e.weight > 0 { lines.append("Gewicht: \(formattedNumber(e.weight)) kg") }
                lines.append("Pause: \(e.pauseBetweenSets)s")
                lines.append("Tempo: \(e.tempo)")
                if let seatLevel = e.seatLevel { lines.append("Sitzhöhe: Stufe \(seatLevel)") }
                if let level = e.level { lines.append("Stufe: \(level)") }
                return lines
            }

            func drawExerciseCard(_ e: KGGExercise) {
                let padding: CGFloat = 12
                let lineHeight: CGFloat = 16
                let lines = exerciseFieldLines(e)
                let valuesHeight = CGFloat(lines.count) * lineHeight

                let nameFont = UIFont.systemFont(ofSize: 12, weight: .medium)
                let nameRectWidth = nameColumnWidth - padding
                let nameBoundingRect = (e.videoTitle as NSString).boundingRect(
                    with: CGSize(width: nameRectWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin],
                    attributes: [.font: nameFont],
                    context: nil
                )

                let contentHeight = max(valuesHeight, nameBoundingRect.height) + padding * 2
                ensureSpace(contentHeight + 8)

                let cardRect = CGRect(x: margin, y: cursorY, width: pageSize.width - margin * 2, height: contentHeight)
                drawCardBorder(cardRect)

                let nameRect = CGRect(x: cardRect.minX + padding, y: cardRect.minY + padding, width: nameRectWidth, height: nameBoundingRect.height)
                (e.videoTitle as NSString).draw(in: nameRect, withAttributes: [.font: nameFont, .foregroundColor: UIColor.black])

                var valueY = cardRect.minY + padding
                let valueX = cardRect.minX + padding + nameColumnWidth
                let valueAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.darkGray
                ]
                for line in lines {
                    (line as NSString).draw(at: CGPoint(x: valueX, y: valueY), withAttributes: valueAttrs)
                    valueY += lineHeight
                }

                cursorY += contentHeight + 8
            }

            startPage()

            if !warmups.isEmpty {
                drawSectionHeader("Aufwärmen")
                for w in warmups.sorted(by: { $0.order < $1.order }) {
                    drawWarmupCard(w)
                }
                cursorY += 10
            }

            if !exercises.isEmpty {
                drawSectionHeader("Training")
                for e in exercises {
                    drawExerciseCard(e)
                }
            }
        }
    }
}
