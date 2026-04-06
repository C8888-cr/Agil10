import SwiftUI

struct RemainingTimeCard: View {
    let remainingSeconds: Int  // ✅ Sekunden statt Minuten
    
    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        
        if minutes == 0 {
            return "\(seconds) Sek"
        } else if seconds == 0 {
            return "\(minutes) Min"
        } else {
            return "\(minutes):\(String(format: "%02d", seconds)) Min"
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Noch \(formattedTime) verbleibend")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    VStack(spacing: 16) {
        RemainingTimeCard(remainingSeconds: 2700)  // 45 Min
        RemainingTimeCard(remainingSeconds: 75)    // 1:15 Min
        RemainingTimeCard(remainingSeconds: 45)    // 45 Sek
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
