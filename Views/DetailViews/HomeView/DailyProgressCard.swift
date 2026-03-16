


import SwiftUI
import SwiftData

struct DailyProgressCard: View {
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject var weeklySettings: WeeklySettings
    @EnvironmentObject var appointmentViewModel: AppointmentViewModel
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    @Query(sort: \Appointment.date) private var allAppointments: [Appointment]

    private var appointments: [Appointment] {
        allAppointments.filter { $0.date > Date().addingTimeInterval(-86400) }
    }

    private var todaysTargetMinutes: Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let dayIndex = weekday == 1 ? 6 : weekday - 2
        return settingsVM.preferences.getGoalFor(dayOfWeek: dayIndex)?.targetMinutes ?? 30
    }

    private var completedMinutes: Int {
        progressVM.completedMinutes
    }

    private var completedRounds: Int {
        guard todaysTargetMinutes > 0 else { return 0 }
        return Int(Double(completedMinutes) / Double(todaysTargetMinutes))
    }

    private var dailyProgressValue: Double {
        guard todaysTargetMinutes > 0 else { return 0 }
        return Double(completedMinutes) / Double(todaysTargetMinutes)
    }

    private var motivationText: String {
        let percent = Int(dailyProgressValue * 100)
        switch percent {
        case 100..<125:
            return "🎉 Ziel übertroffen! Weiter so!"
        case 125..<150:
            return "🔥 Wow, \(percent)%! Du rockst!"
        case 150..<200:
            return "💪 \(percent)%! Unglaublich stark!"
        case 200..<300:
            return "🚀 \(percent)%! Du bist nicht zu stoppen!"
        case 300...:
            return "🌟 \(percent)%! Absolut legendär!"
        default:
            return ""
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heutiges Training")
                        .font(.headline)

                    if completedRounds >= 1 {
                        Text(motivationText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.accent)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        Text("\(todaysTargetMinutes) Min Ziel • \(formatSeconds(progressVM.remainingSeconds)) verbleibend")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .animation(.easeInOut, value: completedRounds)

                Spacer()

                ActivityRingView(progress: dailyProgressValue)
            }

            Divider()

            if let nextAppointment = appointmentViewModel.nextAppointment(from: appointments) {
                CompactAppointmentView(appointment: nextAppointment)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes == 0 { return "\(secs) Sek" }
        if secs == 0 { return "\(minutes) Min" }
        return "\(minutes):\(String(format: "%02d", secs)) Min"
    }
}

#Preview {
    let deps = AppDependencies.shared

    DailyProgressCard()
        .environmentObject(WeeklySettings())
        .environmentObject(deps.progressViewModel)
        .environmentObject(deps.appointmentViewModel)
        .environmentObject(deps.settingsViewModel)
        .modelContainer(deps.modelContainer)
}
