

//  Zeigt Informationen zum ausgewählten Datum (Datum + Termin)
//
//  Dependencies:
//  - AppointmentModel (für Appointment-Typ)
//
//  Verwendet von: CalendarView

import SwiftUI
struct SelectedDateInfoView: View {
    // MARK: - Properties
    let selectedDate: Date
    let appointments: [Appointment]
    let onAddExercise: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                    
                    if appointments.isEmpty {
                        Text("Keine Termine")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(appointments) { appt in
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.accentColor)
                                Text("\(appt.date.timeString) – \(appt.therapist)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: onAddExercise) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accent)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
// MARK: - Preview
struct SelectedDateInfoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Mit Termin
            SelectedDateInfoView(
                selectedDate: Date(),
                appointments: [
                    Appointment(date: Date(), therapist: "Dr. Schmidt", notes: "Kontrolltermin")
                ],
                onAddExercise: { print("Add exercise") }
            )

            // Ohne Termin
            SelectedDateInfoView(
                selectedDate: Date(),
                appointments: [],
                onAddExercise: { print("Add exercise") }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
