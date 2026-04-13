//
//  ProfileHeaderCard.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData
import MapKit
import UserNotifications

struct ProfileHeaderCard: View {
    let user: User
    @Binding var isEditing: Bool

    
    var body: some View {
        VStack(spacing: 16) {
            // ✅ AVATAR mit ACCENT COLOR
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.3),
                                Color.accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 10)
                
                // ✅ BILD ODER INITIALEN
                               if let imageData = user.profileImage,
                                  let uiImage = UIImage(data: imageData) {
                                   Image(uiImage: uiImage)
                                       .resizable()
                                       .scaledToFill()
                                       .frame(width: 100, height: 100)
                                       .clipShape(Circle())
                               } else {
                                   Text(user.initials)
                                       .font(.system(size: 36, weight: .bold, design: .rounded))
                                       .foregroundStyle(Color.accentColor)
                               }
                           }
            // ✅ NAME mit PFEIL
            ZStack {
                
                VStack(spacing: 4) {
                    Text(user.fullName)
                        .font(.title2.bold())
                    
                    if let age = user.age {
                        Text("\(age) Jahre")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if isEditing {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
        .padding(.horizontal)
    }
}
// MARK: - InfoCard

struct InfoCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
        .padding(.horizontal)
    }
}
// MARK: - InfoRow
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Label {
                Text(label)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor.opacity(0.7))
            }
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
    }
}
// MARK: - PraxisCard
