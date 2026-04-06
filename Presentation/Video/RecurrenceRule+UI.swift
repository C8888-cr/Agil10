//
//  RecurrenceRule+.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//

extension RecurrenceRule {
    var icon: String {
        switch self {
        case .single:  return "1.circle"
        case .daily:   return "arrow.clockwise"
        case .weekly:  return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }
}
