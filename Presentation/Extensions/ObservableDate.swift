//
//  ObservableDate.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import SwiftUI

/// Optional: Observable wrapper, falls du ein ObservableObject für Bindings brauchst.
final class ObservableDate: ObservableObject {
    @Published var value: Date
    init( date: Date = Date()) { self.value = date }
}
