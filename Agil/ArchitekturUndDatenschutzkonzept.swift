//
//  ArchitekturUndDatenschutzkonzept.swift
//  Agil10.0
//
//  Created by Christiane Roth on 15.06.26.
//

/*
 # Agil – Architektur- & Datenschutzkonzept (Single Source of Truth)

 > Stand: 2026-06-15. Kurzfassung zum Reinkippen pro Session, damit das Konzept nicht jedes Mal neu erklärt werden muss.

 ## Grundprinzipien
 - Kein zentraler Account, **kein Firebase Auth**. Identität = gerätelokales Schlüsselpaar (Secure Enclave / Keychain).
 - **Keine Patientendaten auf Servern – jemals.** Entwickler hält nichts.
 - Privacy by Design/Default (Art. 25 DSGVO), Datenminimierung (Art. 5).
 - Patient pseudonymisiert: nur eine **Nummer**. Zuordnung Nummer ↔ Person lebt nur in TheOrg, nach Therapieende gelöscht.
 - **Zwei Apps:** Therapeuten-Tablet (iPad) + Patienten-Handy.

 ## Zwei Datenarten

 ### Art 1 – Einzeltherapie-Videos (sensibel, einzigartig)
 - Aufnahme direkt auf dem **Patienten-Handy**, lokal gespeichert.
 - Verschlüsselt at-rest: lokal via iOS Data Protection „complete" (Apple-blind bei gesperrtem Gerät); app-kontrollierte CryptoKit-Verschlüsselung kommt beim iCloud-Backup zum Einsatz.
 - **Nicht von der Praxis reproduzierbar** → Backup sinnvoll (siehe unten).
 - Tagesplanung (wann / wie lange) lokal.

 ### Art 2 – KGG-Videos (Praxis-Bibliothek, praxis-spezifisch)
 - Vorgefertigt vom Therapeuten, für viele Patienten gleich → **kein Patientendatum, sondern Praxis-IP**.
 - Liegen verschlüsselt in einem **Zero-Knowledge-Speicher** (pro Praxis ein Bereich).
 - **Envelope Encryption:** jedes Video hat einen eigenen Datenschlüssel.
 - Handy lädt **nur die zugewiesenen** Videos (per ID), entschlüsselt mit den Keys aus dem QR.
 - „Sperren" ist damit **kryptografisch echt** (kein Key → kein Zugriff), nicht nur UI.

 ### Fortschritt & Bewertung (patientenbezogen, gehört zu Art 1)
 - Fortschrittsanzeige: Anzahl gemachter Übungen und verwendete Gewichte.
 - Pro Übung Tracking inkl. **berechneter prozentualer Veränderung** (mehr/weniger), dargestellt auf einer Skala.
 - Subjektive Bewertung nach jeder Übung: **Smiley + Skala**. Die Skala ist optisch an eine Schmerzskala angelehnt, misst aber bewusst die **Übungs-Schwierigkeit/Anstrengung**, nicht Schmerz.
 - Speicherung: lokal auf dem Patienten-Handy, verschlüsselt; Teil des Art-1-Backups.
 - **MDR-Hinweis:** Berechnung (% Veränderung) und die an die Schmerzskala angelehnte Bewertung sind der heikelste Punkt für die Medizinprodukt-Einordnung → ausdrücklich prüfen lassen. Leitlinie: deskriptiv anzeigen (was war), nicht prescriptiv empfehlen (was tun).

 ## QR-Code (Steuer- & Schlüsselebene, pro Patient/Besuch)
 - Inhalt: zugewiesene Übungs-IDs, Reps, Gewichte, Verlauf + Datenschlüssel der zugewiesenen Videos.
 - Klein genug für QR (nur IDs/Zahlen/Keys, **keine Videobytes**).
 - **Letzter gescannter QR = single source of truth** der Zuordnung.
 - Behandlung als Geheimnis: kurze Gültigkeit, bei Änderung neu generieren.
 - Updates (neue Übung / Reps / Gewichtssteigerung) = neuer QR beim nächsten Besuch.

 ## Backup (nur Art 1)
 - App verschlüsselt Video lokal → Chiffretext in **CloudKit Private DB** (iCloud des Patienten) → Schlüssel in **iCloud Keychain** (von Apple E2E zwischen den Geräten des Nutzers synchronisiert).
 - Neues Handy, gleiche Apple-ID → Keychain bringt Key automatisch → Restore läuft. Apple kann nichts lesen.
 - Entwickler nie Verantwortlicher für dieses Backup (Patient sichert in eigene iCloud).
 - **Grenze:** an Apple-ID gebunden. Android (Kotlin) später = eigener plattform-nativer Backup-Track (Android Keystore).
 - Optional: zusätzliche Wiederherstellungs-Passphrase als Fallback (nicht Default).
 - Art 2 braucht **kein** Backup (auf Tablet reproduzierbar, beim nächsten Besuch neu ladbar).

 ## Termine
 - Über **EventKit** in den Apple-Kalender (App besitzt/verwaltet die Events).
 - Ermöglicht: Absage sichtbar, Verschieben (Tag X löschen → Tag Y anlegen), Sync.
 - Trade-off: Termin liegt im iCloud-Kalender (Apple-lesbar) – bewusst akzeptiert.
 - Mitigation: nur Datum/Uhrzeit/„Termin Praxis X", **keine Therapiedetails** ins Event.
 - `.ics` kommt per Mail (bestehend); Inhalt minimal halten.

 ## DSGVO / MDR
 - Einzeltherapie-Videos = Gesundheitsdaten (Art. 9). Schutz über Verschlüsselung (Art. 32 TOM).
 - Starke E2E-Verschlüsselung senkt Meldepflicht (Art. 33/34) bei Breach.
 - **Medizinprodukt-Status zu prüfen.** Ziel: kein Medizinprodukt, solange die therapeutische Entscheidung beim Menschen bleibt und die App nur **deskriptiv** aufzeichnet/anzeigt/timt. Achtung: die Fortschritts-**Berechnung** (% Veränderung) und die an die Schmerzskala angelehnte **Bewertung** sind potenziell heikel und müssen rechtlich bewertet werden. Keine Diagnose, keine eigenständige Therapieempfehlung durch die Software.
 - Zweckbestimmung schriftlich dokumentieren; Einstufung von MDR-/Datenschutz-Fachperson bestätigen lassen (kein Rechtsrat in diesem Dokument).
 - Keine Tracking-/Analytics-SDKs (jedes SDK = Auftragsverarbeiter).

 ## Tech-Stack / Clean Architecture
 - Swift/SwiftUI + SwiftData (iOS jetzt), Kotlin (Android später).
 - **CryptoKit** für Verschlüsselung; Schlüssel in Secure Enclave / Keychain.
 - Transfer-/Storage-Mechanismus hinter **Protokoll/Interface** kapseln (Dependency Inversion) → iOS/Android und Speicher-Backend später austauschbar.
 - **Firebase wird entfernt.**

 ## Nächste Schritte
 1. `AgilApp.swift` Firebase-frei umbauen (erster committbarer Schritt).
 2. Krypto-Layer (CryptoKit, Keychain/Secure Enclave) als wiederverwendbares Modul.
 3. QR-Format definieren (Payload-Schema, Signatur/Authentizität).
 4. Zero-Knowledge-Speicher-Anbindung (Art 2) hinter Interface.
 5. CloudKit-Backup-Flow (Art 1).
 6. EventKit-Integration für Termine.
 */
