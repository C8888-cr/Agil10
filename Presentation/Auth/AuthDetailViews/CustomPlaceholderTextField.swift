//
//  CustomPlaceholderTextField.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.06.26.
//
import SwiftUI

struct CustomPlaceholderTextField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.gray.opacity(0.7))
                    .padding(.leading, 4)
            }
            TextField("", text: $text)
                .foregroundColor(.black)
        }
    }
}
