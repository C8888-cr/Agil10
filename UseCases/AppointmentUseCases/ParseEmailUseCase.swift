// Features/Appointments/Domain/UseCases/ParseEmailUseCase.swift
import Foundation
/*

struct ParseEmailUseCase {
    private let parser: EmailParserService
    private let addAppointmentUseCase: AddAppointmentUseCase  // ✅ NEU!
    
    init(
        parser: EmailParserService,
        addAppointmentUseCase: AddAppointmentUseCase  // ✅ NEU!
    ) {
        self.parser = parser
        self.addAppointmentUseCase = addAppointmentUseCase
    }
    
    func execute(_ emailText: String) async throws -> [Appointment] {
        print("\n📧 === PARSE EMAIL USE CASE ===")
        
        guard !emailText.isEmpty else {
            print("❌ Email text is empty")
            throw AppointmentError.parsingFailed("Email text is empty")
        }
        
        // ✅ STEP 1: Parse Email → Appointments
        print("🔍 Parsing email text...")
        let parsedAppointments = await parser.parseAppointments(from: emailText)
        
        guard !parsedAppointments.isEmpty else {
            print("⚠️ No appointments found in email")
            throw AppointmentError.parsingFailed("No appointments found in email")
        }
        
        print("✅ Parsed \(parsedAppointments.count) appointments from email")
        
        // ✅ STEP 2: Speichere jeden Termin (mit Duplikat-Check!)
        var savedAppointments: [Appointment] = []
        var skippedCount = 0
        var errorCount = 0
        
        for appointment in parsedAppointments {
            do {
                print("\n💾 Saving appointment: \(appointment.therapist) at \(appointment.date)")
                
                // ✅ AddAppointmentUseCase macht Duplikat-Check + Speichern
                let savedAppointment = try await addAppointmentUseCase.execute(appointment)
                savedAppointments.append(savedAppointment)
                
                print("✅ Saved: \(appointment.therapist)")
                
            } catch AppointmentError.duplicateAppointment {
                print("⚠️ Skipped duplicate: \(appointment.therapist) at \(appointment.date)")
                skippedCount += 1
                
            } catch {
                print("❌ Failed to save: \(appointment.therapist) - \(error)")
                errorCount += 1
            }
        }
        
        print("\n📊 IMPORT RESULT:")
        print("   ✅ Saved: \(savedAppointments.count)")
        print("   ⚠️ Skipped (duplicates): \(skippedCount)")
        print("   ❌ Errors: \(errorCount)")
        print("================================\n")
        
        // ✅ Gib gespeicherte Termine zurück
        return savedAppointments
    }
}
*/
