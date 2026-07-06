import SwiftUI
import AgilCore
import SwiftData

struct PatientCard: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    
    let patient: KGGPatient
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.patientNumber)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("\(patient.exercises.filter { $0.isActive }.count) Übungen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }


               
          
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}
