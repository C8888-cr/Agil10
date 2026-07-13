//
//  EmptyStateView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 29.06.26.
//
import SwiftUI
import AgilCore
import SwiftData

struct EmptyStateView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    
    let onAddTapped: () -> Void
    
    var body: some View {
        
        
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.accent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Keine Patienten")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Fügen Sie einen Patienten hinzu, um zu starten")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                onAddTapped()
            } label: {
                Label("Patient hinzufügen", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.accent)
                    .cornerRadius(12)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
