//
//  EmptyExercisesView.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


import SwiftUI
struct EmptyExercisesView: View {
    // MARK: - Properties
    let onAddExercise: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Keine Übungen eingetragen")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
        /*    Button(action: onAddExercise) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Übungen hinzufügen")
                }
                .font(.subheadline)
                .foregroundColor(.accent)
            }*/
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
// MARK: - Preview
struct EmptyExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyExercisesView(onAddExercise: { print("Add exercise") })
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
