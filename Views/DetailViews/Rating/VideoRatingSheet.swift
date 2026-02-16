import SwiftUI


struct VideoRatingSheet: View {
    let videoTitle: String
    let onRate: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRating: Int = 0
    @State private var showingThankYou = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Text("Video abgeschlossen! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                    
                    Text(videoTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Wie hat dir das Training gefallen?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                // Rating Smileys (adaptiv)
                GeometryReader { geo in
                    let width = geo.size.width
                    let itemWidth = width / 5.0
                    // Basis: 50 % der Segmentbreite, mit min/max
                    let baseEmojiSize = itemWidth * 0.5
                    let emojiSize = min(max(baseEmojiSize, 24), 60)
                    let spacing = itemWidth * 0.1
                    
                    VStack(spacing: 20) {
                        HStack(spacing: spacing) {
                            ForEach(1...5, id: \.self) { rating in
                                Button {
                                    selectedRating = rating
                                    
                                    withAnimation(.spring()) {
                                        showingThankYou = true
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        submitRating()
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Text(RatingHelpers.smileyForRating(rating))
                                            .font(.system(size: emojiSize))
                                            .scaleEffect(selectedRating == rating ? 1.2 : 1.0)
                                            .animation(.spring(response: 0.3), value: selectedRating)
                                            .frame(width: itemWidth,
                                                   height: emojiSize * 1.4,
                                                   alignment: .center)
                                        
                                        Text(RatingHelpers.ratingText(rating))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedRating == rating ? .accentColor : .secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .frame(width: itemWidth)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if showingThankYou && selectedRating > 0 {
                            Text("Danke für dein Feedback!")
                                .font(.headline)
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: width, height: geo.size.height, alignment: .center)
                }
                .frame(height: 180) // reicht für Emoji + Text
                .padding(.horizontal, 24)
                Spacer()
                
                // Skip Button
                Button("Überspringen") {
                    submitRating()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            }
            .padding(.bottom) // etwas Luft nach unten
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitRating() {
        if selectedRating > 0 {
            onRate(selectedRating)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

#Preview("VideoRatingSheet") {
    VideoRatingSheet(
        videoTitle: "Schulter Mobilisation - Übung 1",
        onRate: { rating in
            print("⭐️ Rating:", rating)
        }
    )
}
