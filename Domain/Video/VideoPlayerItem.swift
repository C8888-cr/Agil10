//
//  VideoPlayerItem.swift
//  Agil10.0
//
//  Created by Christiane Roth on 22.03.26.
//
import Foundation

struct VideoPlayerItem: Identifiable {
    let id = UUID()
    let video: Video
    let scheduleId: UUID
}
