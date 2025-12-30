// Features/Appointments/ViewModels/AppointmentViewModel.swift
import Foundation
import SwiftData


@MainActor
class AppointmentViewModel: ObservableObject {
    
    // ✅ AuthService aus AppDependencies holen
       private var authService: AuthService {
           AppDependencies.shared.authService
       }
       
       // ✅ Dann currentUser daraus holen
       private var currentUser: User? {
           authService.currentUser
       }
    // MARK: - Dependencies
    private let markAsNotifiedUseCase: MarkAsNotifiedUseCase
    private let parseEmailUseCase: ParseEmailUseCase
    private let loadAppointmentsUseCase: LoadAppointmentsUseCase
    private let emailParser: EmailParserService
    private let detectAppointmentChangesUseCase: DetectAppointmentChangesUseCase
    private let cancelAppointmentUseCase: CancelAppointmentUseCase
    private let addAppointmentUseCase: AddAppointmentUseCase
    private let emailService: EmailService
    private let deleteAppointmentUseCase: DeleteAppointmentUseCase
    private let parseAppointmentsFromEmailUseCase: ParseAppointmentsFromEmailUseCase
    
    // MARK: - State
    @Published private(set) var appointments: [Appointment] = []
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
            repository: AppointmentRepository,
            emailParser: EmailParserService,
            detectAppointmentChangesUseCase: DetectAppointmentChangesUseCase,
            cancelAppointmentUseCase: CancelAppointmentUseCase,
            addAppointmentUseCase: AddAppointmentUseCase,
            emailService: EmailService,
            markAsNotifiedUseCase: MarkAsNotifiedUseCase,
            loadAppointmentsUseCase: LoadAppointmentsUseCase,
            parseEmailUseCase: ParseEmailUseCase,
            deleteAppointmentUseCase: DeleteAppointmentUseCase,
            parseAppointmentsFromEmailUseCase: ParseAppointmentsFromEmailUseCase
        
        ) {
         //   self.repository = repository
            self.emailParser = emailParser
            self.detectAppointmentChangesUseCase = detectAppointmentChangesUseCase
            self.cancelAppointmentUseCase = cancelAppointmentUseCase
            self.addAppointmentUseCase = addAppointmentUseCase
            self.emailService = emailService
            self.markAsNotifiedUseCase = markAsNotifiedUseCase
            self.loadAppointmentsUseCase = loadAppointmentsUseCase
            self.parseEmailUseCase = parseEmailUseCase
            self.deleteAppointmentUseCase = deleteAppointmentUseCase
            self.parseAppointmentsFromEmailUseCase = parseAppointmentsFromEmailUseCase
            
            Task {
                       await loadAppointments()
                   }
        }
    
    
    
    // MARK: - Public Methods
        
        /// Email-Import
    func parseAppointmentsFromEmail(_ emailText: String) async {
        // ✅ User prüfen
          guard let user = currentUser else {
              setError(.parsingFailed("Kein User eingeloggt"))
              return
          }
        
        
        isLoading = true
        do {
            let appointments = try await parseEmailUseCase.execute(emailText)  // ✅ [Appointment]
            
            // ✅ NEU: Allen Appointments User zuweisen
            appointments.forEach { $0.userId = user.id }
            
            
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
     /// Termine neu laden
     func loadAppointments() async {
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
               await loadAppointments()
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
           userEmail: String
       ) async {
           do {
               try await cancelAppointmentUseCase.execute(
                   appointment: appointment,
                   reason: reason,
                   userEmail: userEmail
               )
               await loadAppointments()
               clearErrors()
           } catch let error as AppointmentError {
               setError(error)
           } catch {
               setError(.deleteFailed(error.localizedDescription))
           }
       }
       
       /// Termin löschen
       func deleteAppointment(_ appointment: Appointment) async {
           do {
               try await deleteAppointmentUseCase.execute(appointment)
               await loadAppointments()
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
               await loadAppointments()
               clearErrors()
           } catch let error as AppointmentError {
               setError(error)
           } catch {
               setError(.saveFailed(error.localizedDescription))
           }
       }
    
    /// UI Refresh
       func refresh() async {
           await loadAppointments()
       }
    
    
    // MARK: - Computed Properties
    var filter: AppointmentFilter {
        AppointmentFilter(appointments)
    }
        
    var nextAppointment: Appointment? {
        filter.nextAppointment
    }
    
    var upcomingAppointments: [Appointment] {
        filter.upcomingAppointments
    }
    
    var otherUpcomingAppointments: [Appointment] {
        filter.otherUpcomingAppointments
       }
    
    var pastAppointments: [Appointment] {
        filter.pastAppointments
    }
    
    var highlightedAppointments: [Appointment] {
        filter.highlightedAppointments
    }
    
    var hasHighlightedAppointments: Bool {
        filter.hasHighlightedAppointments
    }
    

    // MARK: - Calendar Helpers
    
    func hasAppointment(on date: Date) -> Bool {
        appointments.contains { appointment in
            Calendar.current.isDate(appointment.date, inSameDayAs: date)
        }
    }
    
    func appointment(for date: Date) -> Appointment? {
        appointments.first { appointment in
            Calendar.current.isDate(appointment.date, inSameDayAs: date)
        }
    }
    
    // MARK: - Private Methods
       
       private func setError(_ error: AppointmentError) {
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
