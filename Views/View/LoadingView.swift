//
//  LoadingView.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


//
//  LoadingView.swift
//  Agil9.0
//
//  Created by Christiane Roth on 11.11.25.
//

//
//  LoadingView.swift
//  Agil9.0
//
import SwiftUI
struct LoadingView: View {
    @State private var isRotating = false
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accent.opacity(0.1), // Leichtere Telekom Magenta-Töne
                    Color.accent.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Rotierender Kreis mit Logo
                ZStack {
                    // Äußerer Kreis - Animation
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accent,
                        
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .onAppear {
                            withAnimation(
                                Animation.linear(duration: 2)
                                    .repeatForever(autoreverses: false)
                            ) {
                                isRotating = true
                            }
                        }
                    
                    // Innerer Kreis - weiß
                  
              
                        // Dein Agil Logo
                        Image("AgilLogo") // Stelle sicher, dass der Asset-Name "Agil" korrekt ist
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180) // Anpassbare Größe für das Logo
                    
                }
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true)
                    ) {
                        scale = 0.95
                    }
                }
                
                Spacer()
                
                // Loading Text
                VStack(spacing: 8) {
                    Text("Dein Zugang wird vorbereitet...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("Bitte warten")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
#Preview {
    LoadingView()
}
