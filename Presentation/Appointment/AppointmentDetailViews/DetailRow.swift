//
//  DetailRow.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  DetailRow.swift
//  Agil7.0
//
//  Created by Christiane Roth on 07.10.25.
//

// Features/Appointments/Presentation/Views/Components/DetailRow.swift
import SwiftUI
import SwiftData 
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.accent)
                .frame(width: 24)
            
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}
#Preview {
    VStack {
        DetailRow(icon: "calendar", title: "Datum", value: "15. Okt 2024")
        DetailRow(icon: "clock", title: "Uhrzeit", value: "14:30")
        DetailRow(icon: "hourglass", title: "Status", value: "In 3 Tagen")
    }
    .padding()
}
