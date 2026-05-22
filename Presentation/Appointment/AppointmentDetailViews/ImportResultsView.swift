import SwiftUI
import SwiftData

struct ImportResultsView: View {
    @Environment(\.dismiss) private var dismiss

    let changes: AppointmentChanges
    /// Übergibt die getroffenen Entscheidungen an den Aufrufer.
    /// keep   = als .cancelled behalten, delete = ganz löschen.
    let onConfirm: (_ keep: [Appointment], _ delete: [Appointment]) -> Void

    /// Entscheidung pro abgesagtem Termin (Key = appointment.id).
    /// Kein Default – "streng": Fertig erst aktiv, wenn alle entschieden sind.
    @State private var decisions: [UUID: Decision] = [:]

    enum Decision { case keep, delete }

    /// True, wenn jeder abgesagte Termin eine Entscheidung hat.
    private var allDecided: Bool {
        changes.cancelled.allSatisfy { decisions[$0.id] != nil }
    }

    var body: some View {
        NavigationStack {
            List {
                if !changes.added.isEmpty {
                    Section("Neue Termine (\(changes.added.count))") {
                        ForEach(changes.added) { AppointmentSummaryRow(appointment: $0) }
                    }
                }

                if !changes.modified.isEmpty {
                    Section("Geänderte Termine (\(changes.modified.count))") {
                        ForEach(changes.modified) { AppointmentSummaryRow(appointment: $0) }
                    }
                }

                if !changes.cancelled.isEmpty {
                    Section {
                        ForEach(changes.cancelled) { appointment in
                            VStack(alignment: .leading, spacing: 8) {
                                AppointmentSummaryRow(appointment: appointment)
                                Picker("", selection: decisionBinding(for: appointment)) {
                                    Text("Behalten").tag(Decision.keep)
                                    Text("Löschen").tag(Decision.delete)
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Abgesagte Termine (\(changes.cancelled.count))")
                    } footer: {
                        HStack {
                            Button("Alle behalten") { setAll(.keep) }
                            Spacer()
                            Button("Alle löschen", role: .destructive) { setAll(.delete) }
                        }
                        .font(.footnote)
                        .padding(.top, 4)
                    }
                }

                if changes.added.isEmpty && changes.modified.isEmpty && changes.cancelled.isEmpty {
                    Section {
                        Text("Keine neuen Termine gefunden")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Import-Ergebnisse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        confirmAndDismiss()
                    }
                    .disabled(!allDecided)
                }
            }
        }
        .interactiveDismissDisabled(!changes.cancelled.isEmpty)
    }

    // MARK: - Helpers

    /// Binding, das den Picker direkt mit dem decisions-Dictionary verbindet.
    private func decisionBinding(for appointment: Appointment) -> Binding<Decision> {
        Binding(
            get: { decisions[appointment.id] ?? .keep },
            set: { decisions[appointment.id] = $0 }
        )
    }

    private func setAll(_ decision: Decision) {
        for appointment in changes.cancelled {
            decisions[appointment.id] = decision
        }
    }

    private func confirmAndDismiss() {
        let keep = changes.cancelled.filter { decisions[$0.id] == .keep }
        let delete = changes.cancelled.filter { decisions[$0.id] == .delete }
        onConfirm(keep, delete)
        dismiss()
    }
}

// MARK: - Helper View
private struct AppointmentSummaryRow: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appointment.therapist ?? "")
                .font(.headline)
            Text(appointment.formattedDateTime)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    ImportResultsView(
        changes: AppointmentChanges(added: [], modified: [], cancelled: []),
        onConfirm: { _, _ in }
    )
}
