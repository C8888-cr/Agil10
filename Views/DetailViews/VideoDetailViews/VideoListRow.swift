//
//  VideoListRow.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import SwiftUI
struct VideoListRow: View {
    let video: Video
  
    let onTap: (Video) -> Void  // ← VIDEO ÜBERGEBEN! NEU!
    let onFavorite: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            thumbnailView
                .frame(width: 100, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    // Category
                    Label(video.category.rawValue, systemImage: video.category.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Body Region
                    Label(video.bodyRegion.rawValue, systemImage: video.bodyRegion.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Duration & Equipment
                HStack(spacing: 12) {
                    Text(video.formattedDuration)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    
                    if video.equipment != .noEquipment {
                        Label(video.equipment.rawValue, systemImage: video.equipment.icon)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                Button(action: onFavorite) {
                    Image(systemName: video.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(video.isFavorite ? .yellow : .gray)
                }
                
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
            .font(.title3)
        }
        .padding(.horizontal, 16)        // ✅ Padding HIER
        .padding(.vertical, 12)          // ✅ Padding HIER
        .background(Color(.systemBackground))  // ✅ Background HIER
        .contentShape(Rectangle())       // ✅ Für Tap Gesture
        .onTapGesture {
            print("🎬 VideoListRow tapped: \(video.title)")
                  onTap(video)  // ← VIDEO ÜBERGEBEN! NEU!
        }
        .alert("Video löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive, action: onDelete)
        } message: {
            Text("Möchtest du '\(video.title)' wirklich löschen?")
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
#Preview("Standard Row") {
    VideoListRow(
        video: Video(
            title: "Schulter-Mobilisation",
            videoFileName: "shoulder.mov",
            category: .mobility,
            bodyRegion: .legs,
            equipment: .noEquipment,
            durationSeconds: 45,
            fileSizeBytes: 15_000_000, 
        
            rating: 5
        ),
      
        onTap: { video in print("Tapped \(video.title)") },  // ←
        onFavorite: { print("Favorite") },
        onDelete: { print("Delete") }
    )
}
#Preview("List Layout") {
    ScrollView {
        LazyVStack(spacing: 0) {
            ForEach(0..<5) { index in
                VideoListRow(
                    video: Video(
                        title: "Test Video \(index + 1)",
                        videoFileName: "test.mov",
                        category: .mobility,
                        bodyRegion: .fullBody,
                        equipment: .theraband,
                        durationSeconds: 60,
                        fileSizeBytes: 20_000_000,
                        rating: 4
                    ),
                  
                    onTap: { video in print("Tapped \(video.title)") },  // ← 
                    onFavorite: {},
                    onDelete: {}
                )
                
                if index < 4 {
                    Divider()
                }
            }
        }
    }
}
