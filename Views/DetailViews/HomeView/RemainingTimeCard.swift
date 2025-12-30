import SwiftUI
struct RemainingTimeCard: View {
    let remainingMinutes: Int
    
    var body: some View {
        HStack {
            Image(systemName: "clock")
            Text("Noch \(remainingMinutes) Minuten übrig")
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        RemainingTimeCard(remainingMinutes: 45)
        RemainingTimeCard(remainingMinutes: 15)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
