//
//  KGGConfiguration.swift
//  Agil
//
//  KGG-Konfiguration: Single Source of Truth.
//  Zentrale Stelle für 60min-Timer, Video-Settings, etc.
//

import Foundation

public struct KGGConfiguration {
    
    // MARK: - Timing
    
    public static var exerciseVisibilityDurationSeconds: Int = 3600  // 60 Minuten
    
    // MARK: - UI
    
    public static let enforcePortraitOnly: Bool = true
    public static let allowWeightModification: Bool = false
    public static let allowTempoModification: Bool = false
    public static let allowDeletion: Bool = false
    
    // MARK: - Completion Screen
    
    public static let completionTitle: String = "Glückwunsch!"
    public static let completionMessage: String = "Du hast heute dein bestes gegeben — bis zum nächsten Training bei Agil!"
    
    // MARK: - Video Storage
    
    public static let videoFileExtension: String = "agkv"
    public static let videosDirectoryName: String = "KGG/Videos"
    
    // MARK: - Validation
    
    public static let maxQRCodeAgeHours: Int = 24
    
    private init() {}
}
