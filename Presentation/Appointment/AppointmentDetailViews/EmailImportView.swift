/*
// Features/Appointments/Presentation/Views/EmailImportView.swift
import SwiftUI
import SwiftData 

struct EmailImportView: View {
    @Binding var emailText: String
    let onImport: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Info Box
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wie funktioniert's?")
                            .font(.headline)
                        Text("Kopiere die Terminbestätigung aus deiner Email und füge sie hier ein")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Text Editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email-Text")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $emailText)
                        .frame(minHeight: 300)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                
                // Example Format
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beispiel-Format:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("""
                    Terminbestätigung
                    Datum: 29.09.2025
                    Uhrzeit: 12:00
                    Therapeut: Frau Müller
                    """)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Import Button
                Button(action: onImport) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Termine importieren")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.accent, .accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(emailText.isEmpty)
                .opacity(emailText.isEmpty ? 0.5 : 1.0)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Email importieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        onDismiss()
                    }
                }
            }
        }
    }
}
// MARK: - Preview
#Preview {
    EmailImportView(
        emailText: .constant(""),
        onImport: {},
        onDismiss: {}
    )
}
*/

//
//  EmailImportView.swift
//  Agil
//

import SwiftUI
import SwiftData

struct EmailImportView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    @Binding var emailText: String
    let onImport: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Info Box
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wie funktioniert's?")
                            .font(.headline)
                        Text("Kopiere die Terminbestätigung aus deiner Email und tippe auf Einfügen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                // Paste Button
                Button(action: {
                    if let text = UIPasteboard.general.string {
                        emailText = text
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("Text einfügen")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Vorschau des eingefügten Textes
                if !emailText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Eingefügter Text:")
                                .font(.headline)
                            Spacer()
                            Button(action: { emailText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        ScrollView {
                            Text(emailText)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .frame(maxHeight: 250)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                } else {
                    // Leerer Zustand
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.below.ecg")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Noch kein Text eingefügt")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }

                Spacer()

                // Import Button
                Button(action: onImport) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Termine importieren")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [themeManager.currentTheme.accentColor,
                                themeManager.currentTheme.accentColor
                                    ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(emailText.isEmpty)
                .opacity(emailText.isEmpty ? 0.5 : 1.0)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Email importieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    EmailImportView(
        emailText: .constant(""),
        onImport: {},
        onDismiss: {}
    )
}
