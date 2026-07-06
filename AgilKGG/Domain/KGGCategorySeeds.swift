//
//  KGGCategorySeeds.swift
//  Agil10.0
//
//  Created by Christiane Roth on 29.06.26.
//


import Foundation

enum KGGCategorySeeds {
    static let joints: [String] = [
        "art. glenohumeralis",
        "art. cubiti",
        "art. radiocarpalis",
        "art. coxae",
        "art. genus",
        "art. talocruralis",
        "columna vertebralis"
    ]

    static let movements: [String] = [
        "Flexion",
        "Extension",
        "Abduktion",
        "Adduktion",
        "Innenrotation",
        "Außenrotation",
        "Pronation",
        "Supination",
        "Dorsalextension",
        "Plantarflexion",
        "Protraktion",
        "Retraktion"
    ]

    static let devices: [String] = [
        "Theraband",
        "Hantel",
        "Kurzhantel",
        "Langhantel",
        "Seilzug",
        "Latzug",
        "Beinpresse",
        "Stepper",
        "Posturomed",
        "Matte",
        "Gymnastikball",
        "Medizinball"
    ]

    static let muscles: [String] = [
        "Deltoideus",
        "Pectoralis major",
        "Latissimus dorsi",
        "Trapezius",
        "Rectus abdominis",
        "Obliquus externus abdominis",
        "Erector spinae",
        "Gluteus maximus",
        "Quadriceps femoris",
        "Hamstrings",
        "Gastrocnemius",
        "Soleus",
        "Biceps brachii",
        "Triceps brachii"
    ]

    static func values(for type: KGGCategoryType) -> [String] {
        switch type {
        case .muskel: return muscles
        case .gelenk: return joints
        case .geraet: return devices
        case .bewegungsrichtung: return movements
        }
    }
}
