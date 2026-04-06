import SwiftUI
struct RatingEmojiView: View {
    let rating: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Text(RatingHelpers.smileyForRating(index + 1))
                    .font(.system(size: index == rating - 1 ? 14 : 9))
                    .opacity(index >= rating ? 0.4 : 1.0)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(height: 20)
    }


    
    private func emojiSize(for index: Int, container: CGSize) -> CGFloat {
        let baseSize = container.height * 0.6  // 60% der Höhe nutzen
        let normalSize = min(max(baseSize * 0.7, 6), 10)  // Klein + sicher
        let selectedSize = min(normalSize * 1.6, 14)       // 60% GRÖSSER, aber max 14pt
        return index == rating - 1 ? selectedSize : normalSize
    }
    
    private func colorOpacity(for index: Int) -> Double {
        if index < rating - 1 { return 1.0 }
        else if index == rating - 1 { return 1.0 }
        else { return 0.35 }
    }
}

#Preview("RatingEmojiView") {
    VStack(spacing: 20) {
        Text("Rating Emojis")
            .font(.headline)
        
        ForEach(1...5, id: \.self) { rating in
            HStack {
                Text("Rating \(rating):")
                    .font(.caption)
                    .frame(width: 80, alignment: .leading)
                
                RatingEmojiView(rating: rating)
                
                Text(RatingHelpers.ratingText(rating))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
}
