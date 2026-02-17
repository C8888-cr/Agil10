//
//  PraxisDataManager.swift
//  Agil
//
//  Created by Christiane Roth on 30.11.25.
//


//
//  PraxisDataManager.swift
//  Agil9.0
//
//  Created by Christiane Roth on 11.11.25.
//
import Foundation

class PraxisDataManager {
    static let shared = PraxisDataManager()
    
    // ✅ Feste UUIDs für Praxen (jedes Mal dieselben!)
    static let praxis1Id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let praxis2Id = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let praxis3Id = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let praxis4Id = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let praxis5Id = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let praxis6Id = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    
    let praxen: [Praxis] = [
        Praxis(
            id: PraxisDataManager.praxis1Id,  // ✅ 1
            name: "agil Eschersheim",
            email: "agil-eschersheim@physio-agil.de",
            addresse: "Kirchhainer Straße 29",
            city: "Frankfurt Eschersheim",
            postalCode: "60433",
            latitude: nil,
            longitude: nil,
            telefon: "069 95108770",
            website: "https://physio-agil.de"
        ),
        Praxis(
            id: PraxisDataManager.praxis2Id,  // ✅ 2
            name: "agil Preungesheim",
            email: "agil-preungesheim@physio-agil.de",
            addresse: "Kantapfelstraße 26",
            city: "Frankfurt Preungesheim",
            postalCode: "60435",
            latitude: nil,
            longitude: nil,
            telefon: "069 95497666",
            website: "https://physio-agil.de"
        ),
        Praxis(
            id: PraxisDataManager.praxis3Id,  // ✅ 3
            name: "agil Langen",
            email: "langen@physio-agil.de",
            addresse: "Bahnstraße 37",
            city: "Langen",
            postalCode: "63225",
            latitude: nil,
            longitude: nil,
            telefon: "06103 2086030",
            website: "https://physio-agil.de"
        ),
        Praxis(
            id: PraxisDataManager.praxis4Id,  // ✅ 4
            name: "agil Ostend",
            email: "agil-ostend@physio-agil.de",
            addresse: "Juchostraße 7",
            city: "Frankfurt",
            postalCode: "60385",
            latitude: nil,
            longitude: nil,
            telefon: "069 449693",
            website: "https://physio-agil.de"
        ),
        Praxis(
            id: PraxisDataManager.praxis5Id,  // ✅ 5
            name: "agil Dornbusch",
            email: "agil-dornbusch@physio-agil.de",
            addresse: "Eschersheimer Landstraße 311",
            city: "Frankfurt",
            postalCode: "60320",
            latitude: nil,
            longitude: nil,
            telefon: "069 94598465",
            website: "https://physio-agil.de"
        ),
        Praxis(
            id: PraxisDataManager.praxis6Id,  // ✅ 6
            name: "agil Alt-Eschersheim",
            email: "agil-alt-eschersheim@physio-agil.de",
            addresse: "Alt-Eschersheim 34, 60433 Frankfurt Alt Eschersheim",
            city: "Frankfurt Alt Eschersheim",
            postalCode: "60433",
            latitude: nil,
            longitude: nil,
            telefon: "069 577662",
            website: "https://physio-agil.de"
        )
    ]
    
    private init() {}
    
    // ✅ Helper: Praxis by ID finden
       func getPraxis(by id: UUID) -> Praxis? {
           praxen.first { $0.id == id }
       }
       
       // ✅ Helper: Name by ID
       func getPraxisName(for id: UUID?) -> String {
           guard let id = id,
                 let praxis = getPraxis(by: id) else {
               return "Keine Praxis ausgewählt"
           }
           return praxis.name
       }
}
