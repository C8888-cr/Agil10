

//  Zeigt Informationen zum ausgewählten Datum (Datum + Termin)
//
//  Dependencies:
//  - AppointmentModel (für Appointment-Typ)
//
//  Verwendet von: CalendarView

import SwiftUI
import AgilCore


struct SelectedDateInfoView: View {
    // MARK: - Properties
    let selectedDate: Date
    let appointments: [Appointment]
    let onAddAppointment: () -> Void
    let onTapAppointment: (Appointment) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    
     // MARK: - Body
     var body: some View {
         VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        
                        Text("")
     
                        if appointments.isEmpty {
                            Text("Keine Termine")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        } else {
                                                  ForEach(appointments) { appt in
                                                      AppointmentBody(appointment: appt)
                                                          .contentShape(Rectangle())
                                                          .onTapGesture { onTapAppointment(appt) }
                                                  }
                                              }
                        
                        
                        
                    }
     
     Spacer()
     

     }
     }
         .glassCard()
     }
     }
     
     
    
    
  
// MARK: - Preview
struct SelectedDateInfoView_Previews: PreviewProvider {
    
    // ✅ Mock IDs definieren
    private static let mockUserId = UUID()
    private static let mockPraxisId = UUID()
    
    
    static var previews: some View {
        VStack(spacing: 16) {
            SelectedDateInfoView(
                selectedDate: Date(),
                appointments: [
                    Appointment(date: Date(),
                                therapist: "Dr. Schmidt",
                                notes: "Kontrolltermin",
                                userId: mockUserId,
                                praxisId: mockPraxisId
                               )
                ],
                onAddAppointment: { print("Add appointment") },
                onTapAppointment: { _ in print("Tapped") }  // ← NEU
            )
            
            SelectedDateInfoView(
                selectedDate: Date(),
                appointments: [],
                onAddAppointment: { print("Add appointment") },
                onTapAppointment: { _ in print("Tapped") }  // ← NEU
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
