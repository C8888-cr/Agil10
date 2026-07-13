//
//  KGGTodayViewModel.swift
//  Agil10.0
//
//  Created by Christiane Roth on 29.06.26.
//
import SwiftUI
import Combine
import SwiftData
import CoreImage.CIFilterBuiltins
import UIKit
import AgilCore

@MainActor
final class KGGTodayViewModel: ObservableObject {
    @Published var selectedPatients: [KGGPatient] = []
    @Published var allPatients: [KGGPatient] = []
    @Published var searchText: String = ""
    @Published var filteredPatients: [KGGPatient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let modelContext: ModelContext
    private let praxisId: UUID
    
    
    @Published var startQRImage: UIImage?
    private var currentStartToken: KGGStartSessionToken?
    
    
    
    init(modelContext: ModelContext, praxisId: UUID) {
        self.modelContext = modelContext
        self.praxisId = praxisId
    }
    
    func loadPatients() {
           isLoading = true
           defer { isLoading = false }
           
           print("DEBUG KGGTodayViewModel.loadPatients() - praxisId: \(praxisId)")  // ← Debug
           
           do {
               var descriptor = FetchDescriptor<KGGPatient>()
               descriptor.predicate = #Predicate<KGGPatient> { $0.praxisId == praxisId }
               descriptor.sortBy = [SortDescriptor(\KGGPatient.patientNumber)]
               allPatients = try modelContext.fetch(descriptor)
               
               print("DEBUG KGGTodayViewModel: Geladen \(allPatients.count) Patienten")  // ← Wie viele?
               
               applySearch()
           } catch {
               print("Fehler beim Laden: \(error)")
           }
       }
    
    
    func applySearch() {
        if searchText.isEmpty {
            filteredPatients = allPatients
        } else {
            filteredPatients = allPatients.filter {
                $0.patientNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.diagnosis.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func addToToday(_ patient: KGGPatient) {
            guard !selectedPatients.contains(where: { $0.id == patient.id }),
                  selectedPatients.count < 3 else { return }
            selectedPatients.append(patient)
            generateStartQRIfNeeded()
        }
    
    func removeFromToday(_ patient: KGGPatient) {
            selectedPatients.removeAll { $0.id == patient.id }
        }
        
        func clearToday() {
            selectedPatients.removeAll()
        }
        
        /// Prüft vor dem Öffnen des Auswahl-Sheets, ob noch Platz ist (max. 3).
        func canOpenPatientSelector() -> Bool {
            guard selectedPatients.count < 3 else {
                errorMessage = "Bitte zuerst einen Patienten aus der Liste entfernen (max. 3 gleichzeitig möglich)."
                return false
            }
            return true
        }

    func generateStartQRIfNeeded() {
        guard startQRImage == nil else { return }
        regenerateStartQR()
    }

    func regenerateStartQR() {
        let token = KGGStartSessionToken()
        currentStartToken = token
        guard let qrString = try? KGGStartSessionCoder.encode(token) else { return }
        startQRImage = Self.makeQRImage(from: qrString)
    }

    private static func makeQRImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
    }
