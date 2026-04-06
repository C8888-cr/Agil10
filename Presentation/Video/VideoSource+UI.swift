//
//  VideoSource+UI.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//

extension VideoSource {
    var icon: String {
        switch self {
        case .recorded: return "camera.fill"
        case .downloaded: return "arrow.down.circle.fill"
        case .cloud: return "cloud.fill"
        }
    }
}
