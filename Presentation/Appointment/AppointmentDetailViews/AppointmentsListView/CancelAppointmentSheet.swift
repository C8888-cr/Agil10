//
//  CancelAppointmentSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 24.02.26.
//
import SwiftUI
import SwiftData

struct CancelAppointmentSheet: View {
    let appointment: Appointment
    let user: User
    @Binding var isCancelling: Bool
    let onCancel: (String?) -> Void
    let onDismiss: () -> Void
    
    @State private var reason = ""
    @State private var showingMailPicker = false    // ✅ NEU - State hier!
       @State private var mailTo = ""                  // ✅ NEU
       @State private var mailSubject = ""             // ✅ NEU
       @State private var mailBody = ""                //
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
/*
    // ✅ Welche Mail-Apps sind installiert?
    private var availableMailApps: [(name: String, scheme: String)] {
        let apps: [(name: String, scheme: String)] = [
            ("Apple Mail",  "mailto:"),
            ("Gmail",       "googlegmail://"),
            ("Outlook",     "ms-outlook://"),
            ("Yahoo Mail",  "ymail://"),
            ("Web.de Mail", "webdemail://"),
            ("GMX Mail",    "gmxmail://")
        ]
       
         let filtered = apps.filter {
         URL(string: $0.scheme).map { UIApplication.shared.canOpenURL($0) } ?? false
         }
         
         return filtered.isEmpty ? [("Apple Mail", "mailto:")] : filtered
         
         
         }*/
    private var availableMailApps: [(name: String, scheme: String)] {
        return [
            ("Mail", "mailto:"),
            ("Gmail", "googlegmail://"),
            ("Outlook", "ms-outlook://")
        ]
    }
    /*
    private func openWith(scheme: String) {
          let encodedSubject = mailSubject
              .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
          let encodedBody = mailBody
              .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
          let encodedTo = mailTo
              .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
          
          var urlString = ""
          
          switch scheme {
          case "googlegmail://":
              // Gmail hat eigenes URL-Schema
              urlString = "googlegmail:///co?to=\(encodedTo)&subject=\(encodedSubject)&body=\(encodedBody)"
          case "ms-outlook://":
              // Outlook Schema
              urlString = "ms-outlook://compose?to=\(encodedTo)&subject=\(encodedSubject)&body=\(encodedBody)"
          case "webdemail://":
                 urlString = "webdemail://compose?to=\(encodedTo)&subject=\(encodedSubject)&body=\(encodedBody)"
             case "gmxmail://":
                 urlString = "gmxmail://compose?to=\(encodedTo)&subject=\(encodedSubject)&body=\(encodedBody)"
          default:
              // Standard mailto: (Apple Mail, Yahoo etc.)
              urlString = "mailto:\(encodedTo)?subject=\(encodedSubject)&body=\(encodedBody)"
          }
        if let url = URL(string: urlString) {
               UIApplication.shared.open(url) { success in
                   if !success {
                       // ✅ Fallback auf Apple Mail wenn App nicht installiert
                       print("❌ \(scheme) nicht gefunden - Fallback Apple Mail")
                       let fallback = "mailto:\(encodedTo)?subject=\(encodedSubject)&body=\(encodedBody)"
                       if let fallbackUrl = URL(string: fallback) {
                           UIApplication.shared.open(fallbackUrl)
                       }
                   }
               }
           }
       }
         */
    
    private func openWith(scheme: String) {
        let encodedSubject = mailSubject
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = mailBody
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedTo = mailTo
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        var urlString = ""
        
        switch scheme {
        case "webdemail://":
            // Web.de über Browser öffnen
            urlString = "https://email.web.de/mail/compose?to=\(encodedTo)&subject=\(encodedSubject)&body=\(encodedBody)"
            
        default:
            urlString = "mailto:\(encodedTo)?subject=\(encodedSubject)&body=\(encodedBody)"
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    // MARK: - Mail öffnen
    private func openMailApp() {
        
        
        let to = "christiane100385@web.de"
        let subject = "Terminabsage - \(appointment.dateString)"
        
        var body = """
        Guten Tag,
        ich möchte meinen folgenden Termin absagen:
        Datum: \(appointment.dateString)
        Uhrzeit: \(appointment.timeString)
        Therapeut: \(appointment.therapist)
        """
        
        if !reason.isEmpty {
            body += """
            
            
            Grund: \(reason)
            """
        }
        
        body += """
        
        
        Mit freundlichen Grüßen
            \(user.firstName)  
            \(user.lastName)         
        """
        
        showingMailPicker = true
            mailTo = to
            mailSubject = subject
            mailBody = body
        
        
        

                }
            

    
    
    var body: some View {
        NavigationStack {
            Form {
                // Termin-Info
                Section("Termin") {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        Text(appointment.dateString)
                    }
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        Text(appointment.timeString)
                    }
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        Text(appointment.therapist)
                    }
                }
                
                // Grund (optional)
                Section {
                    TextEditor(text: $reason)
                        .frame(minHeight: 80)
                        .overlay(
                            Group {
                                if reason.isEmpty {
                                    Text("Grund der Absage (optional)")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                            },
                            alignment: .topLeading
                        )
                } header: {
                    Text("Grund (optional)")
                } footer: {
                    // ✅ Klarer Hinweis für den User
                    Text("Die Mail-App öffnet sich mit deiner vorausgefüllten Absage. Bitte tippe dort auf Senden.")
                        .font(.caption)
                }
                
                // Absagen Button
                Section {
                    Button(action: {
                        openMailApp()
                    }) {
                        HStack {
                            Spacer()
                            if isCancelling {
                                ProgressView()
                            } else {
                                Text("Termin absagen")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isCancelling)
                }
            }
            .navigationTitle("Termin absagen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .disabled(isCancelling)
                }
            }
                // ✅ App-Auswahl ActionSheet
                           .confirmationDialog(
                               "Mit welcher App möchtest du die Mail senden?",
                               isPresented: $showingMailPicker,
                               titleVisibility: .visible
                           ) {
                               // ✅ Nur installierte Apps anzeigen
                               ForEach(availableMailApps, id: \.scheme) { app in
                                   Button(app.name) {
                                       openWith(scheme: app.scheme)
                                       onCancel(reason.isEmpty ? nil : reason)
                                       dismiss()
                                   }
                               }
                               
                               Button("Abbrechen", role: .cancel) { }
                           }
                       }
                   }
               }
