//
//  PrivacyPolicyView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 10.05.26.
//


//
//  PrivacyPolicyView.swift
//  Agil10.0
//
//  Datenschutzerklärung – wird aus dem Profil heraus geöffnet.
//

import SwiftUI
import AgilCore

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Datenschutz bei Agil")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Stand: \(formattedToday)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)

                    section(
                        title: "Wer wir sind",
                        body: """
                        Agil ist eine App zur Unterstützung deines Trainings und zur \
                        Verwaltung deiner Physiotherapie-Termine. Diese Datenschutzerklärung \
                        beschreibt, welche Daten wir verarbeiten und wie wir sie schützen.
                        """
                    )

                    section(
                        title: "Welche Daten wir verarbeiten",
                        body: """
                        Bei der Nutzung von Agil verarbeiten wir folgende Daten:

                        • Profildaten: Name, E-Mail-Adresse, ausgewählte Praxis und Therapeut
                        • Termindaten: Datum, Uhrzeit, Therapeut, Praxis, optionale Notizen
                        • Trainingsdaten: angesehene Videos, Wiederholungen, Fortschritt
                        • Einstellungen: Erinnerungszeiten, Theme, Expertenmodus

                        Sensible Gesundheitsdaten verarbeiten wir nur soweit unbedingt nötig \
                        (z. B. Physiotherapie-Bezug deiner Termine).
                        """
                    )

                    section(
                        title: "Wo deine Daten gespeichert werden",
                        body: """
                        Alle deine Daten – Profil, Termine und Trainingsdaten – werden \
                                                ausschließlich lokal auf deinem Gerät gespeichert. Es gibt keine \
                                                zentralen Benutzerkonten und keine Server. Für die Anmeldung legst \
                                                du ein gerätegebundenes Konto an; dein Passwort wird niemals im \
                                                Klartext gespeichert, sondern nur als kryptografischer Hash \
                                                (SHA‑256 mit zufälligem Salt) in der gerätegeschützten Keychain \
                                                abgelegt. Es werden keinerlei Anmeldedaten an uns oder Dritte \
                                                übertragen.
                        """
                    )

                    section(
                        title: "Kalender-Integration",
                        body: """
                        Während die App geöffnet ist, prüft Agil automatisch, ob deine bereits verknüpften Termine im iPhone-Kalender extern geändert wurden, und gleicht diese mit der App ab. Es findet keine Übertragung an Server statt.
                        Wenn du der Kalender-Integration zustimmst, greift Agil lesend \
                        und schreibend auf den Kalender deines Geräts zu. Wir lesen die \
                        Termine ausschließlich, um dir beim Planen neuer Praxis-Termine \
                        eine Übersicht über deine bestehenden Verpflichtungen zu geben. \
                        Beim Anlegen, Ändern oder Absagen eines Praxis-Termins in Agil \
                        werden die entsprechenden Einträge in deinem Geräte-Kalender \
                        erstellt, aktualisiert oder entfernt.

                        Wichtig: Sämtliche Verarbeitung erfolgt ausschließlich lokal auf \
                        deinem Gerät. Es findet keine Übertragung von Kalender-Daten an \
                        Agil-Server oder sonstige Dritte statt. Wir verarbeiten nur die \
                        für die Anzeige notwendigen Felder (Titel, Start- und Endzeit, \
                        Quelle/Farbe). Teilnehmer, Beschreibungen, Anhänge und sonstige \
                        Detail-Felder werden nicht ausgelesen.

                        Du kannst die Erlaubnis jederzeit unter \
                        Einstellungen → Agil → Kalender widerrufen. Agil funktioniert \
                        dann ohne Kalender-Integration weiter.

                        Rechtsgrundlage: Art. 6 Abs. 1 lit. a DSGVO (Einwilligung).
                        """
                    )

                    section(
                        title: "Benachrichtigungen",
                        body: """
                        Wenn du Termin-Erinnerungen aktivierst, erstellt Agil lokale \
                        Benachrichtigungen auf deinem Gerät. Diese werden nicht über \
                        externe Dienste verarbeitet.
                        """
                    )

                    section(
                        title: "Kamera und Mikrofon",
                        body: """
                        Wenn du eigene Übungsvideos aufnimmst, greift Agil mit deiner \
                        Erlaubnis auf Kamera und Mikrofon deines Geräts zu. Die \
                        aufgenommenen Videos werden lokal gespeichert und nicht an \
                        Agil-Server übertragen.
                        """
                    )

                    section(
                        title: "Standort",
                        body: """
                        Bei einigen Terminen werden Standortdaten der Praxis (Adresse, \
                        Koordinaten) gespeichert, um dir auf Wunsch die Navigation zu \
                        ermöglichen. Diese Daten kommen aus dem Praxis-Verzeichnis und \
                        nicht aus deiner aktuellen Position.
                        """
                    )

                    section(
                        title: "Deine Rechte",
                        body: """
                        Du hast jederzeit das Recht auf:

                        • Auskunft über die zu deiner Person gespeicherten Daten
                        • Berichtigung unrichtiger Daten
                        • Löschung deiner Daten (über „Account löschen" im Profil)
                        • Widerruf erteilter Einwilligungen
                        • Datenübertragbarkeit
                        • Beschwerde bei einer Datenschutzaufsichtsbehörde

                        Rechtsgrundlagen für die Verarbeitung sind \
                        Art. 6 Abs. 1 lit. a DSGVO (Einwilligung) und \
                        Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung).
                        """
                    )

                    section(
                        title: "Kontakt",
                        body: """
                        Bei Fragen zum Datenschutz kannst du uns jederzeit erreichen:

                        E-Mail: datenschutz@agil-app.de

                        (Bitte ersetze diese Adresse durch deine echte Kontaktadresse, \
                        bevor du die App veröffentlichst.)
                        """
                    )

                    // Disclaimer
                    Text("Hinweis: Diese Datenschutzerklärung ist ein Entwurf und ersetzt keine Rechtsberatung. Bitte vor Veröffentlichung von einer Datenschutz-Fachperson prüfen lassen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding(.top, 16)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Datenschutz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helpers

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.accentColor)
            Text(body)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
}

#Preview {
    PrivacyPolicyView()
        .environmentObject(ThemeManager())
}
