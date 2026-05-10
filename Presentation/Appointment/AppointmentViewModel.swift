// Features/Appointments/ViewModels/AppointmentViewModel.swift
import Foundation
import SwiftData


@MainActor
class AppointmentViewModel: ObservableObject {
    
    
    private let modelContext: ModelContext
    private let session: SessionManager
    
       
    private var currentUser: User? {
           session.currentUser  
       }
    
    
    // MARK: - Dependencies
    private let markAsNotifiedUseCase: MarkAsNotifiedUseCase
//    private let parseEmailUseCase: ParseEmailUseCase
    private let loadAppointmentsUseCase: LoadAppointmentsUseCase
    private let emailParser: EmailParserService
    private let detectAppointmentChangesUseCase: DetectAppointmentChangesUseCase
    private let cancelAppointmentUseCase: CancelAppointmentUseCase
    private let addAppointmentUseCase: AddAppointmentUseCase
    private let emailService: EmailService
    private let deleteAppointmentUseCase: DeleteAppointmentUseCase
    private let parseAppointmentsFromEmailUseCase: ParseAppointmentsFromEmailUseCase
    private let calendarSync: CalendarSyncService?
    
    
    // MARK: - State
   
    @Published var isLoading = false
    @Published var showingError = false
    
    // MARK: - Error
    @Published private(set) var currentError: AppointmentError?
    @Published private(set) var validationError: ValidationError?
    
   
    
    
    
    // MARK: - Computed Error Properties
      var errorMessage: String? {
          currentError?.errorDescription ?? validationError?.errorDescription
      }
      
      var errorRecoverySuggestion: String? {
          currentError?.recoverySuggestion ?? validationError?.recoverySuggestion
      }
      
      var hasError: Bool {
          currentError != nil || validationError != nil
      }
    
    
    // MARK: - Init (mit allen Dependencies)
        init(
            modelContext: ModelContext,
            session: SessionManager,
            repository: AppointmentRepository,
            emailParser: EmailParserService,
            detectAppointmentChangesUseCase: DetectAppointmentChangesUseCase,
            cancelAppointmentUseCase: CancelAppointmentUseCase,
            addAppointmentUseCase: AddAppointmentUseCase,
            emailService: EmailService,
            markAsNotifiedUseCase: MarkAsNotifiedUseCase,
            loadAppointmentsUseCase: LoadAppointmentsUseCase,
        //    parseEmailUseCase: ParseEmailUseCase,
            deleteAppointmentUseCase: DeleteAppointmentUseCase,
            parseAppointmentsFromEmailUseCase: ParseAppointmentsFromEmailUseCase,
            calendarSync: CalendarSyncService? = nil
        
        ) {
         //   self.repository = repository
            self.modelContext = modelContext
            self.session = session
            self.emailParser = emailParser
            self.detectAppointmentChangesUseCase = detectAppointmentChangesUseCase
            self.cancelAppointmentUseCase = cancelAppointmentUseCase
            self.addAppointmentUseCase = addAppointmentUseCase
            self.emailService = emailService
            self.markAsNotifiedUseCase = markAsNotifiedUseCase
            self.loadAppointmentsUseCase = loadAppointmentsUseCase
          //  self.parseEmailUseCase = parseEmailUseCase
            self.deleteAppointmentUseCase = deleteAppointmentUseCase
            self.parseAppointmentsFromEmailUseCase = parseAppointmentsFromEmailUseCase
            self.calendarSync = calendarSync

        }
    
    
    
    // MARK: - Public Methods
 /*
        /// Email-Import
    func parseAppointmentsFromEmailOld(_ emailText: String) async {
        // ✅ User prüfen
          guard let user = currentUser else {
              setError(.parsingFailed("Kein User eingeloggt"))
              return
          }
        print("👤 Current User: \(user.id)")
        
        isLoading = true
        do {
            let appointments = try await parseEmailUseCase.execute(emailText)  // ✅ [Appointment]
            print("📧 Parsed \(appointments.count) appointments")
            
            
            // ✅ User zuweisen
                for apt in appointments {
                    apt.userId = user.id
                    print("   → \(apt.therapist) | userId set to: \(apt.userId?.uuidString ?? "FAIL")")
                }
                
                await loadAppointments()
            clearErrors()
            print("✅ Imported: \(appointments.count) appointments")  // ✅ FIX!
        } catch let error as AppointmentError {
            setError(error)
        } catch let error as ValidationError {
            validationError = error
            showingError = true
        } catch {
            setError(.parsingFailed(error.localizedDescription))
        }
        isLoading = false
    }
*/
    /// Email-Import mit Changes-Detection
    func parseAppointmentsFromEmail(_ emailText: String) async throws -> AppointmentChanges {
        // ✅ User prüfen
        guard let user = currentUser else {
            setError(.parsingFailed("Kein User eingeloggt"))
            throw AppointmentError.parsingFailed("Kein User eingeloggt")
        }
        
        print("👤 Current User: \(user.id)")
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // ✅ Use Case aufrufen (parsed + speichert + DetectChanges)
            let changes = try await parseAppointmentsFromEmailUseCase.execute(emailText: emailText)
            
            // ✅ User zu ALLEN neuen/geänderten Terminen hinzufügen
            for apt in changes.added + changes.modified + changes.cancelled {
                apt.userId = user.id
                print("   → \(apt.therapist) | userId set to: \(apt.userId?.uuidString ?? "FAIL")")
            }
            
            // ✅ Liste refreshen
            
            clearErrors()
            
            print("✅ Email import: \(changes.changesSummary)")
            
            return changes
            
        } catch let error as AppointmentError {
            setError(error)
            throw error
        } catch let error as ValidationError {
            validationError = error
            showingError = true
            throw error
        } catch {
            setError(.parsingFailed(error.localizedDescription))
            throw error
        }
    }
     /// Termine neu laden
/*     func loadAppointments() async {
         guard let user = currentUser else {
                appointments = []
                return
            }
         isLoading = true
         do {
             appointments = try await loadAppointmentsUseCase.execute(for: user)
             clearErrors()
         } catch let error as AppointmentError {
            setError(error)
         } catch {
             setError(.saveFailed(error.localizedDescription))
         }
         isLoading = false
     }
 */

    func addAppointmentManual(
        date: Date,
        therapist: String,
        locationName: String? = nil,
        locationAddress: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        notes: String? = nil,
        durationMinutes: Int = 45
    ) async {
        do {
               let savedAppointment = try await addAppointmentUseCase.executeManual(
                   date: date,
                   therapist: therapist,
                   locationName: locationName,
                   locationAddress: locationAddress,
                   latitude: latitude,
                   longitude: longitude,
                   notes: notes,
                   durationMinutes: durationMinutes
               )
            print("✅ Appointment saved: \(savedAppointment.therapist) on \(savedAppointment.date)")
            
      
            clearErrors()
            
        } catch {
            // Dein Error-Handling
            if let error = error as? AppointmentError {
                setError(error)
            } else if let error = error as? ValidationError {
                validationError = error
                showingError = true
            } else {
                setError(.saveFailed(error.localizedDescription))
            }
        }
    }

    
    
    /// Termin hinzufügen
       func addAppointment(_ appointment: Appointment) async {
           // ✅ User prüfen
            guard let user = currentUser else {
                setError(.saveFailed("Kein User eingeloggt"))
                return
            }
            
            // ✅ NEU: User zuweisen
           appointment.userId = user.id
            
           do {
               try await addAppointmentUseCase.execute(appointment)
              
               clearErrors()
           } catch let error as AppointmentError {
               setError(error)
           } catch let error as ValidationError {
               validationError = error
               showingError = true
           } catch {
               setError(.saveFailed(error.localizedDescription))
           }
       }
    

       
       /// Termin absagen (mit Email)
       func cancelAppointment(
           _ appointment: Appointment,
           reason: String?,
           userEmail: String,
           userName: String
       ) async {
           
           // ✅ practiceEmail hier im ViewModel auflösen
              let practiceEmail: String
              if let praxisId = currentUser?.praxisId,
                 let praxis = PraxisDataManager.shared.getPraxis(by: praxisId),
                 let email = praxis.email {
                  practiceEmail = email
              } else {
                  practiceEmail = "praxis@physio-agil.de"
              }
           
           
           do {
               try await cancelAppointmentUseCase.execute(
                   appointment: appointment,
                   reason: reason,
                   userEmail: userEmail,
                   userName: userName,
                   practiceEmail: practiceEmail
               )
             
               clearErrors()
           } catch let error as AppointmentError {
               setError(error)
           } catch {
               setError(.deleteFailed(error.localizedDescription))
           }
       }
       
       
    /// Termin löschen
    func deleteAppointment(_ appointment: Appointment) async {
        // Erst aus iPhone-Kalender entfernen (best effort)
        if let eventId = appointment.calendarEventIdentifier,
           let calendarSync = calendarSync,
           calendarSync.authorizationStatus == .authorized {
            do {
                try await calendarSync.deleteEvent(identifier: eventId)
                print("🗑️ Kalender-Event gelöscht: \(eventId)")
            } catch {
                // Wenn Kalender-Delete fehlschlägt: Termin trotzdem aus Agil löschen.
                // Der Kalender-Eintrag bleibt dann verwaist, aber das ist besser, als den
                // ganzen Delete abzubrechen.
                print("⚠️ Kalender-Event konnte nicht gelöscht werden: \(error)")
            }
        }
        
        // Bestehender Code:
        do {
            try await deleteAppointmentUseCase.execute(appointment)
            clearErrors()
        } catch let error as AppointmentError {
            setError(error)
        } catch {
            setError(.deleteFailed(error.localizedDescription))
        }
    }
       
       /// Als benachrichtigt markieren
       func markAsNotified(_ appointment: Appointment) async {
           do {
               try await markAsNotifiedUseCase.execute(appointment)
       
               clearErrors()
           } catch let error as AppointmentError {
               setError(error)
           } catch {
               setError(.saveFailed(error.localizedDescription))
           }
       }
    
    /// UI Refresh
       func refresh() async {
        
       }
    
    
    // MARK: - Computed Properties
    func filter(for appointments: [Appointment]) -> AppointmentFilter {
           AppointmentFilter(appointments)
       }
       
       func nextAppointment(from appointments: [Appointment]) -> Appointment? {
           filter(for: appointments).nextAppointment
       }
       
       func upcomingAppointments(from appointments: [Appointment]) -> [Appointment] {
           filter(for: appointments).upcomingAppointments
       }
       
       func otherUpcomingAppointments(from appointments: [Appointment]) -> [Appointment] {
           filter(for: appointments).otherUpcomingAppointments
       }
       
       func pastAppointments(from appointments: [Appointment]) -> [Appointment] {
           filter(for: appointments).pastAppointments
       }
       
       func highlightedAppointments(from appointments: [Appointment]) -> [Appointment] {
           filter(for: appointments).highlightedAppointments
       }
       
       func hasHighlightedAppointments(in appointments: [Appointment]) -> Bool {
           filter(for: appointments).hasHighlightedAppointments
       }
       
       // MARK: - Calendar Helpers
       
       func hasAppointment(on date: Date, in appointments: [Appointment]) -> Bool {
           appointments.contains { appointment in
               Calendar.current.isDate(appointment.date, inSameDayAs: date)
           }
       }
       
       func appointment(for date: Date, in appointments: [Appointment]) -> Appointment? {
           appointments.first { appointment in
               Calendar.current.isDate(appointment.date, inSameDayAs: date)
           }
       }
    
    // MARK: - Private Methods
       
    func setError(_ error: AppointmentError) {
           currentError = error
           validationError = nil
           showingError = true
       }
     func clearErrors() {
           currentError = nil
           validationError = nil
           showingError = false
       }
    
}
