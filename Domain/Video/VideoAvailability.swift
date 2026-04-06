//
//  VideoAvailability.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


enum VideoAvailability {
    case available
    case cloudOnly
    case downloading(progress: Double)
    case requiresPurchase
}