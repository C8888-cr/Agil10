
import SwiftUI
import SwiftData

struct ImportResultsView: View {
    @Environment(\.dismiss) private var dismiss
    let changes: AppointmentChanges
    
    var body: some View {
        NavigationStack {
            List {
                if !changes.added.isEmpty {
                    Section("Neue Termine (\(changes.added.count))") {
                        ForEach(changes.added) { appointment in
                            AppointmentSummaryRow(appointment: appointment)
                        }
                    }
                }
                
                if !changes.modified.isEmpty {
                    Section("Geänderte Termine (\(changes.modified.count))") {
                        ForEach(changes.modified) { appointment in
                            AppointmentSummaryRow(appointment: appointment)
                        }
                    }
                }
                
                if !changes.cancelled.isEmpty {
                    Section("Abgesagte Termine (\(changes.cancelled.count))") {
                        ForEach(changes.cancelled) { appointment in
                            AppointmentSummaryRow(appointment: appointment)
                        }
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}
// MARK: - Helper View
private struct AppointmentSummaryRow: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appointment.therapist)
                .font(.headline)
            Text(appointment.formattedDateTime)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
// MARK: - Preview
#Preview {
    let sampleChanges = AppointmentChanges(
        added: [],
        modified: [],
        cancelled: []
    )
    
    ImportResultsView(changes: sampleChanges)
}
