//
//  MockVideo.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.04.26.
//

// MockVideo.swift  (Domain)

import UIKit

// MARK: - Mock Video

func createMockVideo(title: String = "Schulter Mobilisation") -> Video {
    Video(
        title: title,
        videoFileName: "shoulder.mov",
        category: .mobility,
        bodyRegion: .cervicalSpine,
        equipment: .noEquipment,
        durationSeconds: 120,
        defaultRepetitions: 3,
        defaultPauseSeconds: 30,
        loopDurationSeconds: 120,
        rating: 1
    )
}

// MARK: - Mock VideoSchedule

func createMockSchedule(completed: Bool = false, rating: Int? = nil) -> VideoSchedule {
    let schedule = VideoSchedule(
        scheduledDate: Date(),
        orderIndex: 0,
        video: createMockVideo(),
        customRepetitions: 4,
        customPauseSeconds: 45,
        customLoopDurationSeconds: 180
    )
    schedule.isCompleted = completed
    schedule.rating = rating
    if completed { schedule.completedAt = Date() }
    return schedule
}

// MARK: - Mock Thumbnails

extension UIImage {
    static func previewThumbnail(
        systemName: String = "figure.flexibility",
        size: CGSize = CGSize(width: 160, height: 90),
        backgroundColor: UIColor = .systemTeal,
        tintColor: UIColor = .white
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            backgroundColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .thin)
            if let symbol = UIImage(systemName: systemName, withConfiguration: config)?
                .withTintColor(tintColor, renderingMode: .alwaysOriginal) {
                let x = (size.width - symbol.size.width) / 2
                let y = (size.height - symbol.size.height) / 2
                symbol.draw(at: CGPoint(x: x, y: y))
            }
        }
    }
}
