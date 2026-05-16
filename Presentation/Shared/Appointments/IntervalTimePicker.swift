//
//  IntervalTimePicker.swift
//  Agil10.0
//
//  Created by Christiane Roth on 16.05.26.
//


import SwiftUI
import UIKit

struct IntervalTimePicker: UIViewRepresentable {
    @Binding var date: Date
    var minuteInterval: Int = 10

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.minuteInterval = minuteInterval
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "de_DE")
        
        // ← NEU: Picker darf sich seinen Platz nehmen
        picker.setContentHuggingPriority(.defaultLow, for: .horizontal)
        picker.setContentCompressionResistancePriority(.required, for: .horizontal)
        picker.setContentCompressionResistancePriority(.required, for: .vertical)
        
        picker.addTarget(
            context.coordinator,
            action: #selector(Coordinator.dateChanged(_:)),
            for: .valueChanged
        )
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        if uiView.date != date {
            uiView.date = date
        }
        uiView.minuteInterval = minuteInterval
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: IntervalTimePicker
        init(_ parent: IntervalTimePicker) {
            self.parent = parent
        }

        @objc func dateChanged(_ sender: UIDatePicker) {
            parent.date = sender.date
        }
    }
}
