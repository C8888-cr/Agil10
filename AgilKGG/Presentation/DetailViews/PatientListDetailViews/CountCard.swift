//
//  CountCard.swift
//  Agil10.0
//
//  Created by Christiane Roth on 29.06.26.
//

import SwiftUI
import SwiftData
import AgilCore


 struct CountCard: View {
     let count: Int
     @EnvironmentObject var themeManager: ThemeManager
     @Environment(\.modelContext) private var modelContext

     
     
     var body: some View {
         
         
         HStack {
             VStack(alignment: .leading, spacing: 4) {
                 Text("Patienten")
                     .font(.caption)
                     .foregroundStyle(.secondary)
                 Text("\(count) gesamt")
                     .font(.subheadline)
                     .fontWeight(.medium)
             }
             Spacer()
             Image(systemName: "person.2.fill")
                 .font(.headline)
                 .foregroundStyle(.accent)
         }
         .padding()
         .background(Color(.systemBackground))
         .clipShape(RoundedRectangle(cornerRadius: 12))
         .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
     }
 }
