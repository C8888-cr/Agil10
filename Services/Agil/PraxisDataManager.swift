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
    
    let praxen: [Praxis] = [
        
        Praxis(
            id: 1,
            name: "agil Eschersheim",
           
            email: "agil-eschersheim@physio-agil.de",
            addresse: "Kirchhainer Straße 29",
            city: "Frankfurt Eschersheim",
            postalCode: "60433",
            latitude: nil,
            longitude: nil,
            telefon: "069 95108770",
            website: nil
        ),
        
        Praxis(
                   id: 2,
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
            id: 3,
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
            id:4,
            name: "agil Ostend",
            email: "agil-ostend@physio-agil.de",
            addresse: "Juchostraße 7",
            city:"Frankfurt",
            postalCode: "60385",
            latitude: nil,
            longitude: nil,
            telefon: "069 449693",
            website: "https://physio-agil.de"
        ),
        
        Praxis(
            id:5,
            name: "agil Dornbusch",
            email: "agil-dornbusch@physio-agil.de",
            addresse: "Eschersheimer Landstraße 311",
            city: "Frankfurt",
            postalCode: "603020",
            latitude: nil,
            longitude: nil,
         
            telefon: "069 94598465",
            website: "https://physio-agil.de"
        ),
        
        Praxis(
            id:6,
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
    private init() {
        
    }
}
