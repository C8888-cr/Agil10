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
                                                VStack(alignment: .leading, spacing: 10) {
                                                    AppointmentSummaryRow(appointment: appointment)
                                                    
                                                    
                                                    HStack(spacing: 8) {
                                                                                        decisionButton(
                                                                                            title: "Behalten",
                                                                                            systemImage: "checkmark",
                                                                                            isSelected: decisions[appointment.id] == .keep,
                                                                                            selectedColor: .accentColor
                                                                                        ) {
                                                                                            decisions[appointment.id] = .keep
                                                                                        }
                                                                                        decisionButton(
                                                                                            title: "Löschen",
                                                                                            systemImage: "trash",
                                                                                            isSelected: decisions[appointment.id] == .delete,
                                                                                            selectedColor: .red
                                                                                        ) {
                                                                                            decisions[appointment.id] = .delete
                                                                                        }
                                                                                    }
                                                    
                                                    
                                                    
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

    /// Ein Entscheidungs-Button. Gewählt = farbige Füllung,
        /// nicht gewählt = Liquid-Glass-Outline (sichtbar "noch nicht entschieden").
    /// Ein Entscheidungs-Button im System-Glas-Stil.
        /// Gewählt = farbiger Text + Symbol, nicht gewählt = gedämpft ohne Symbol.
        @ViewBuilder
        private func decisionButton(
            title: String,
            systemImage: String,
            isSelected: Bool,
            selectedColor: Color,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) {
                HStack(spacing: 6) {
                    if isSelected {
                        Image(systemName: systemImage)
                    }
                    Text(title)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
                .font(.subheadline)
                .foregroundStyle(isSelected ? selectedColor : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.glass)
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
