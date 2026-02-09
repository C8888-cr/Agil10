 // MARK: - Compact Appointment View
 struct CompactAppointmentView: View {
     let appointment: Appointment
     
     var body: some View {
         VStack(alignment: .leading, spacing: 4) {
             HStack(spacing: 4) {
                 Image(systemName: "calendar")
                     .font(.caption)
                     .foregroundColor(.accent)
                 Text("Nächster Termin")
                     .font(.caption)
                     .foregroundColor(.secondary)
             }
             HStack(spacing: 12) {
                 Text(appointment.timeString)
                     .font(.title3)
                     .fontWeight(.semibold)
                     .foregroundColor(.primary)

                 VStack(alignment: .leading, spacing: 2) {
                     Text(appointment.therapist)
                         .font(.caption)
                         .foregroundColor(.secondary)
                     Text(appointment.locationName ?? "")
                         .font(.caption)
                         .foregroundColor(.secondary)
                     
                     // ✅ Notizen optional
                                       if let notes = appointment.notes, !notes.isEmpty {
                                           Text(notes)
                                               .font(.caption2)
                                               .foregroundColor(.secondary)
                                               .italic()
                                       }
                 }
                 Spacer()
             }
         }
         .frame(maxWidth: .infinity, alignment: .leading)
     }
 }