//
//  KGGCompletionView.swift
//  Agil
//
//  "Glückwunsch"-Screen nach 60min oder nach Training.
//  Animierte Celebration + Nachricht.
//

import SwiftUI

public struct KGGCompletionView: View {
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var emojiOffset: [CGFloat] = [-30, 0, 30].map { _ in 0 }
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.accentColor)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    VStack(spacing: 12) {
                        Text(KGGConfiguration.completionTitle)
                            .font(.title.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Text(KGGConfiguration.completionMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .opacity(opacity)
                }
                .frame(maxWidth: .infinity, maxHeight: 300, alignment: .center)
                
                Spacer()
                
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        Text(["🎉", "💪", "⭐️"][index])
                            .font(.system(size: 32))
                            .opacity(opacity)
                            .offset(y: emojiOffset[index])
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            animateEntrance()
        }
    }
    
    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            opacity = 1
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            scale = 1
        }
        
        for index in 0..<3 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.35 + Double(index) * 0.1)) {
                emojiOffset[index] = -20
            }
        }
    }
}

#Preview {
    KGGCompletionView()
}
