//
//  VideoRepositoryProtocol.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import Foundation


@MainActor
protocol VideoRepositoryProtocol {
    func createVideo(metadata: Video) async throws
    func fetchAllVideos(for user: User) async throws -> [Video]
    func fetchVideo(by id: UUID) async throws -> Video?
    func updateVideo(metadata: Video) async throws
    func deleteVideo(metadata: Video) async throws
    func toggleFavorite(metadata: Video) async throws
    func updateLastUsed(metadata: Video) async throws
    
    func fetchFilteredVideos(
        category: ExerciseCategory?,
        bodyRegion: BodyRegion?,
        equipment: Equipment?,
        searchText: String?,
        favoritesOnly: Bool,
        for user: User
    ) async throws -> [Video]
    
    func uploadVideo(
        from sourceURL: URL,
        title: String,
        category: ExerciseCategory,
        bodyRegion: BodyRegion,
        equipment: Equipment,
    //    defaultRepetitions: Int,
    //    defaultPauseSeconds: Int,
    //    loopDurationSeconds: Int?,
        for user: User
    ) async throws -> Video
}

   
