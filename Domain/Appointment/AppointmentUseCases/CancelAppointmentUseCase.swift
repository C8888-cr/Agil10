import Foundation

struct CancelAppointmentUseCase {
    private let repository: AppointmentRepository
    private let emailService: EmailService
    private let calendarSync: CalendarSyncService?

    init(
        repository: AppointmentRepository,
        emailService: EmailService,
        calendarSync: CalendarSyncService? = nil
    ) {
        self.repository = repository
        self.emailService = emailService
        self.calendarSync = calendarSync
    }

    /// User-initiierte Absage (Button in der App).
    func execute(
        appointment: Appointment,
        reason: String?,
        userEmail: String,
        userName: String,
        practiceEmail: String
    ) async throws {
        print("🚫 User-Absage für: \(appointment.therapist ?? "kein Therapeut")")
        try await applyCancellation(appointment)
        // Hinweis: Email-Versand ist hier (wie bisher) noch nicht verdrahtet.
    }

    /// Absage aus dem Email-Import (verschwundener Termin).
    /// Kein Email-Versand – die Praxis hat den Termin selbst entfernt.
    func executeFromEmailImport(appointment: Appointment) async throws {
        print("🚫 Import-Absage für: \(appointment.therapist ?? "kein Therapeut")")
        try await applyCancellation(appointment)
    }

    // MARK: - Private

    /// Setzt den Status auf .cancelled, speichert und benennt den
    /// verknüpften Apple-Event auf "Physio agil: Abgesagt" um.
    /// Single Source of Truth fürs Absagen.
    private func applyCancellation(_ appointment: Appointment) async throws {
        appointment.status = .cancelled
        try await repository.save(appointment)
        print("✅ Status gesetzt: \(appointment.status)")

        await renameCalendarEvent(appointment)
    }

    /// Benennt den verknüpften Apple-Event um. Status steht bereits auf
    /// .cancelled → Builder liefert automatisch "Physio agil: Abgesagt".
    /// Sync-Fehler sind kein Hard-Fail – die Absage in Agil gilt trotzdem.
    private func renameCalendarEvent(_ appointment: Appointment) async {
        guard let sync = calendarSync,
              sync.authorizationStatus == .authorized,
              let eventId = appointment.calendarEventIdentifier else {
            return
        }

        let endDate = appointment.date.addingTimeInterval(
            TimeInterval(appointment.durationMinutes * 60)
        )
        let title = AppointmentCalendarTitleBuilder.build(for: appointment)

        do {
            try await sync.updateEvent(
                identifier: eventId,
                title: title,
                startDate: appointment.date,
                endDate: endDate,
                location: appointment.displayLocation,
                notes: appointment.notes
            )
            print("✅ Apple-Event auf 'Abgesagt' umbenannt: \(eventId)")
        } catch {
            print("⚠️ Apple-Event-Umbenennung fehlgeschlagen: \(error)")
        }
    }
}
