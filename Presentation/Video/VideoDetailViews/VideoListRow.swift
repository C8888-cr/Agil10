//
//  VideoListRow.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import SwiftUI
struct VideoListRow: View {
    let video: Video
  
    let onTap: (Video) -> Void  
    let onFavorite: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            thumbnailView
                .frame(width: 100, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack(spacing: 6) {
                    // Category
                    Label(video.category.rawValue, systemImage: video.category.icon)
                        .lineLimit(1)
                      
                    
                    // Body Region
                    Label(video.bodyRegion.rawValue, systemImage: video.bodyRegion.icon)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                // Duration & Equipment
                HStack(spacing: 6) {
                    Text(video.formattedDuration)
                    
                    if video.equipment != .noEquipment {
                        Label(video.equipment.rawValue, systemImage: video.equipment.icon)
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                    }
                }
                .font(.caption2)
                
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                Button(action: onFavorite) {
                    Image(systemName: video.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(video.isFavorite ? .yellow : .gray)
                }
                
                if let onDelete {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    
                    .font(.title3)
                }
            }
        }
        .dynamicTypeSize(.small ... .large)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
       
        .onTapGesture {
            print("🎬 VideoListRow tapped: \(video.title)")
                  onTap(video)  // ← VIDEO ÜBERGEBEN! NEU!
        }
        .alert("Video löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) { onDelete?() }
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

#Preview("Große Schrift") {
    VideoListRow(
        video: Video(
            title: "Schulter-Mobilisation",
            videoFileName: "shoulder.mov",
            category: .mobility,
            bodyRegion: .legs,
            equipment: .noEquipment,
            durationSeconds: 45,
            fileSizeBytes: 15_000_000,
            loopDurationSeconds: 60,
            rating: 5
        ),
        onTap: { video in print("Tapped") },
        onFavorite: {},
        onDelete: {}
    )
    .environment(\.dynamicTypeSize, .accessibility3)  // ← extremste Größe
}
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
        
            loopDurationSeconds: 60, rating: 5
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
                        loopDurationSeconds: 60,
                        rating: 4,
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
