//
//  PrüfunterlageRechtUndDatenschutz.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.06.26.
//

/*
 # Prüfunterlage – Rechtsanwalt (Medizinprodukterecht) & Datenschutzbeauftragter

 **App:** Agil (Arbeitstitel) – Plattform für Physiotherapie-/KGG-Praxen
 **Stand:** 2026-06-15
 **Zweck dieses Dokuments:** faktische, technische und organisatorische Beschreibung der Anwendung sowie konkrete Prüffragen. Es ist **keine eigene rechtliche Bewertung** und ersetzt diese nicht.

 ---

 ## 1. Kurzbeschreibung der Anwendung

 Agil ist eine Plattform, die einer Physiotherapie-/KGG-Praxis ermöglicht:

 - **Einzeltherapie:** Während der Behandlung werden Übungsvideos aufgenommen, getimt und tageweise geplant. Der Patient macht die Übungen zu Hause anhand der Videos nach.
 - **KGG (Krankengymnastik am Gerät):** Der Therapeut wählt aus einer **praxis-spezifischen** Bibliothek vorgefertigter Übungsvideos aus, weist sie einem Patienten zu und stellt Wiederholungen/Gewichte/Verlauf ein.
 - **Termine:** Verwaltung von Praxisterminen inkl. Synchronisation in den Gerätekalender.
 - **Fortschritt & Bewertung:** Anzeige, wie viele Übungen gemacht und welche Gewichte verwendet wurden; pro Übung wird die **prozentuale Veränderung** (mehr/weniger) berechnet und auf einer Skala dargestellt. Nach jeder Übung eine subjektive Bewertung via Smiley und Skala; die Skala ist optisch an eine Schmerzskala angelehnt, erfragt jedoch die **Schwierigkeit/Anstrengung der Übung**, nicht Schmerz.

 Es gibt **zwei getrennte Anwendungen:** eine Therapeuten-App (Tablet) und eine Patienten-App (Handy).

 **Erklärte Zweckbestimmung (zu prüfen):** Agil ist als reine **Organisations- und Bereitstellungsplattform** gedacht. Die App nimmt auf, zeigt an, timet und stellt **deskriptive** Fortschrittswerte dar (z. B. prozentuale Veränderung der Gewichte sowie eine subjektive Schwierigkeitsbewertung). Sie trifft **keine** medizinischen Entscheidungen, gibt **keine** eigenständigen Therapieempfehlungen ab und nimmt **keine** diagnostische Auswertung vor. Sämtliche therapeutischen Entscheidungen (Auswahl der Übungen, Wiederholungen, Gewichtssteigerungen) trifft ausschließlich der Therapeut.

 ---

 ## 2. Datenarten und Sensibilität

 | Datenart | Inhalt | Einordnung |
 |---|---|---|
 | Einzeltherapie-Videos | individuelle Aufnahmen des Patienten bei der Übung | Gesundheitsdaten, Art. 9 DSGVO; einzigartig/nicht reproduzierbar |
 | KGG-Videos | generische, vom Therapeuten erstellte Übungsvideos der Praxis | kein Personenbezug; Praxis-IP |
 | Zuordnung/Reps/Gewichte/Verlauf | welche Übung mit welchen Parametern, zeitlicher Verlauf | gesundheitsbezogen (Trainingsparameter) |
 | Fortschritt & Bewertung | Anzahl/Gewichte, berechnete prozentuale Veränderung, Smiley- und Schwierigkeitsskala | gesundheitsbezogen, Art. 9 |
 | Termine | Datum, Uhrzeit, Praxis | personenbezogen, niedrig-sensibel |
 | Patientenkennung | nur eine **Nummer** in der App | pseudonymisiert |

 Die Zuordnung Nummer ↔ Klarname existiert **nur im bestehenden Praxissystem (TheOrg)**, nicht in der App, und wird nach Therapieende gelöscht.

 ---

 ## 3. Datenflüsse und Speicherorte

 - **Einzeltherapie-Videos:** ausschließlich auf dem Patienten-Handy, verschlüsselt at-rest. Optionales Backup in die **patienten-eigene iCloud**: Die App verschlüsselt das Video lokal, bevor es übertragen wird; in der iCloud liegt nur Chiffretext, der Schlüssel liegt in der iCloud Keychain (von Apple Ende-zu-Ende synchronisiert). Der App-Anbieter hat **keinen Zugriff**; Apple sieht nur Chiffretext.
 - **KGG-Videos:** in einem **Zero-Knowledge-Speicher**, pro Praxis getrennt, mit Envelope-Verschlüsselung (jedes Video eigener Schlüssel). Der Speicher hält nur Chiffretext und **keine** Schlüssel. Kein Personenbezug.
 - **Zuordnung/Reps/Gewichte/Verlauf:** werden per **QR-Code in Person** vom Tablet auf das Patienten-Handy übertragen und dort verschlüsselt gespeichert. **Nie auf einem Server.**
 - **Termine:** über das Betriebssystem (EventKit) im Gerätekalender des Patienten; Inhalt minimiert (nur Datum/Uhrzeit/„Termin Praxis X", keine Therapiedetails).
 - **Authentifizierung:** keine zentrale Nutzerverwaltung, keine Konten beim Anbieter (Firebase Auth wird entfernt).

 **Kernaussage:** Beim App-Anbieter liegen **zu keinem Zeitpunkt** personenbezogene Patientendaten.

 ---

 ## 4. Technische und organisatorische Maßnahmen (Art. 32 DSGVO)

 - Verschlüsselung at-rest auf den Endgeräten (CryptoKit, Schlüssel in Secure Enclave / Keychain).
 - Ende-zu-Ende-Prinzip beim KGG-Speicher (Server hält nur Chiffretext, nie Schlüssel).
 - Pseudonymisierung und Datenminimierung „by design/default" (Art. 25).
 - Keine Tracking- oder Analytics-SDKs.
 - Löschkonzept: Zuordnung/Parameter nach Therapieende; Nummern-Mapping in TheOrg gelöscht.
 - Minimale Angriffsfläche durch Verzicht auf zentrale Datenhaltung.

 ---

 ## 5. Rollen (zu klären/bestätigen)

 - **Praxis:** Verantwortliche für die Patienten-/Gesundheitsdaten.
 - **App-Anbieter (Entwickler):** Rolle zu klären – da konstruktiv keine personenbezogenen Daten verarbeitet/gehalten werden, möglicherweise weder Verantwortlicher noch Auftragsverarbeiter.
 - **Apple / Cloud-Anbieter:** ggf. Auftragsverarbeiter des jeweiligen Patienten (eigene iCloud) – zu klären.
 - Bedarf an Auftragsverarbeitungsverträgen (Art. 28) – mit wem?

 ---

 ## 6. Prüffragen an den Rechtsanwalt (MDR / MPDG)

 1. Ist die App nach MDR bzw. der Leitlinie MDCG 2019-11 ein **Medizinprodukt (Medical Device Software)**? Trägt die Einordnung als reine Bereitstellungs-/Organisationsplattform ohne eigene medizinische Funktion?
 2. Welche Funktionen oder Formulierungen müssten wir **vermeiden** (z. B. automatische Steigerungsempfehlungen, eigenständige Auswertung), um sicher nicht als Medizinprodukt zu gelten?
 3. Wie dokumentieren wir die **Zweckbestimmung** rechtssicher?
 4. Haftungsrechtliche Aspekte und nötige Disclaimer/AGB einer reinen „Plattform".
 5. **Besonders zu bewerten:** Die App **berechnet** die prozentuale Veränderung der Gewichte und stellt sie auf einer Skala dar. Macht diese deskriptive Berechnung/Verlaufsdarstellung die App zum Medizinprodukt (Stichwort Monitoring/Auswertung), oder bleibt sie als bloße Anzeige selbst-eingegebener Werte außerhalb?
 6. **Besonders zu bewerten:** Eine an die Schmerzskala angelehnte Bewertung erfragt die Übungs-Schwierigkeit/Anstrengung (nicht Schmerz). Genügt diese Abgrenzung, oder sollten Form, Bezeichnung und Skalierung weiter von klinischen Schmerz-/Assessment-Instrumenten entfernt werden?

 ---

 ## 7. Prüffragen an den Datenschutzbeauftragten (DSGVO)

 1. Trägt das Konstrukt (keine Patientendaten beim Anbieter, E2E-Verschlüsselung, patienten-eigenes Backup), sodass der Anbieter nicht Verantwortlicher/Auftragsverarbeiter ist?
 2. Reichen Pseudonymisierung (Nummer) und Löschkonzept für Art. 5, 9 und 25?
 3. Sind die TOM nach Art. 32 angemessen? Bestehen Lücken?
 4. Welche Dokumente sind nötig: Verzeichnis von Verarbeitungstätigkeiten (Art. 30), Datenschutz-Folgenabschätzung (Art. 35, wegen Art.-9-Daten?), Datenschutzerklärung, AV-Verträge (Art. 28), Patienteneinwilligung (Art. 9 Abs. 2 lit. a)?
 5. Ist die Synchronisation der Termine in den Apple-Kalender datenschutzrechtlich so vertretbar?
 6. Bestätigung der Rollenverteilung Praxis ↔ Anbieter ↔ Apple.

 ---

 ## 8. Was bewusst NICHT umgesetzt wird (für die Bewertung relevant)

 - Keine zentrale Nutzerverwaltung / keine Konten.
 - Keine Speicherung von Patientendaten auf Servern des Anbieters.
 - Keine medizinische Auswertung oder Empfehlung durch die Software.
 */
