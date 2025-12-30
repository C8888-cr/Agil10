//
//  VideoCard.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  VideoCard.swift
//  Agil7.0
//
//  Created by Christiane Roth on 08.10.25.
//

//
//  VideoCard.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.01.25.
//
import SwiftUI
struct VideoCard: View {
    let video: Video
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack {
                thumbnailView
                
                // Overlay Icons
                VStack {
                    HStack {
                        // Favorite Button
                        Button(action: onFavorite) {
                            Image(systemName: video.isFavorite ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundStyle(video.isFavorite ? .yellow : .white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Delete Button
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(8)
                    
                    Spacer()
                    
                    // Duration Badge
                    HStack {
                        Spacer()
                        
                        Text(video.formattedDuration)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.7))
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }
            }
            .aspectRatio(4/3, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Info Section
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    // Category Icon
                    HStack(spacing: 4) {
                        Image(systemName: video.category.icon)
                            .font(.caption2)
                        Text(video.category.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    
                    // Body Region
                    HStack(spacing: 4) {
                        Image(systemName: video.bodyRegion.icon)
                            .font(.caption2)
                        Text(video.bodyRegion.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Equipment
                if video.equipment != .noEquipment {
                    HStack(spacing: 4) {
                        Image(systemName: video.equipment.icon)
                            .font(.caption2)
                        Text(video.equipment.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(.blue)
                }
            }
            .padding(.top, 8)
        }
        .onTapGesture(perform: onTap)
        .alert("Video löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive, action: onDelete)
        } message: {
            Text("Möchtest du '\(video.title)' wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }
    
    private var thumbnailView: some View {
        Group {
            if let thumbnailFileName = video.thumbnailFileName,
               let thumbnail = ThumbnailGeneratorService.shared.loadThumbnail(fileName: thumbnailFileName) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(uiImage: ThumbnailGeneratorService.shared.getThumbnailOrPlaceholder(fileName: nil))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
    }
}
// MARK: - Preview
#Preview("Standard Video") {
    VideoCard(
        video: Video(
            title: "Schulter-Mobilisation",
            videoFileName: "shoulder.mov",
            category: .mobility,
            bodyRegion: .back,
            equipment: .noEquipment,
            durationSeconds: 45,
            fileSizeBytes: 15_000_000,
      
            rating: 5
        ),
        onTap: { print("Tapped") },
        onFavorite: { print("Favorite toggled") },
        onDelete: { print("Delete") }
    )
    .frame(width: 180)
    .padding()
}
#Preview("Favorite Video") {
    VideoCard(
        video: {
            let video = Video(
                title: "Rücken-Kräftigung mit Widerstandsband",
                videoFileName: "back.mov",
                category: .stretching,
                bodyRegion: .back,
                equipment: .theraband,
                durationSeconds: 120,
                fileSizeBytes: 45_000_000,
         
                rating: 4
            )
            video.isFavorite = true
            return video
        }(),
        onTap: { print("Tapped") },
        onFavorite: { print("Favorite toggled") },
        onDelete: { print("Delete") }
    )
    .frame(width: 180)
    .padding()
}
#Preview("Grid Layout") {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(0..<6) { _ in
                VideoCard(
                    video: Video(
                        title: "Test Video",
                        videoFileName: "test.mov",
                        category: .mobility,
                        bodyRegion: .fullBody,
                        equipment: .noEquipment,
                        durationSeconds: 60,
                        fileSizeBytes: 20_000_000,
                      
                        rating: 1
                    ),
                    onTap: {},
                    onFavorite: {},
                    onDelete: {}
                )
            }
        }
        .padding()
    }
}
