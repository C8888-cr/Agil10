
import SwiftUI
import SwiftData


struct StatusEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    
    let user: User
    
    // MARK: - Trial berechnen
    private var trialDaysRemaining: Int? {
        let trialDuration: TimeInterval = 90 * 24 * 60 * 60 // 3 Monate
        let trialEnd = user.createdAt.addingTimeInterval(trialDuration)
        let remaining = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: trialEnd
        ).day ?? 0
        return remaining > 0 ? remaining : nil
    }
    
    private var isInTrial: Bool {
        trialDaysRemaining != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // MARK: - Aktueller Status Banner
                        currentStatusBanner
                        
                        // MARK: - Feature Liste
                        featureList
                        
                        Spacer()
                        
                        // MARK: - Buttons
                        actionButtons
                    }
                }
                
            }
            .navigationTitle("Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Current Status Banner
    private var currentStatusBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: user.isPremium ? "crown.fill" : "person.circle.fill")
                    .font(.title)
                    .foregroundStyle(user.isPremium ? .yellow : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.isPremium ? "PREMIUM" : "Standard")
                        .font(.headline.bold())
                        .foregroundStyle(user.isPremium ? .yellow : .primary)
                    
                    if let days = trialDaysRemaining, !user.isPremium {
                        Text("🎁 Noch \(days) Tage gratis Premium")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if !user.isPremium {
                        Text("5 Videos pro Tag verfügbar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Alle Features freigeschaltet")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Spacer()
            }
            .padding()
            .background(
                user.isPremium
                    ? Color.yellow.opacity(0.15)
                    : Color(.systemBackground)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        user.isPremium ? Color.yellow.opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Feature Liste
    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Was ist enthalten?")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                FeatureRow(
                    icon: "play.circle.fill",
                    title: "Videos ansehen",
                    description: user.isPremium ? "Unbegrenzt" : "5 Videos pro Tag",
                    isAvailable: true,
                    isPremiumFeature: false
                )
                FeatureRow(
                    icon: "calendar.badge.plus",
                    title: "Videos planen",
                    description: "Trainingsplan erstellen",
                    isAvailable: true,
                    isPremiumFeature: false
                )
                FeatureRow(
                    icon: "bell.badge.fill",
                    title: "Benachrichtigungen",
                    description: "Erinnerungen aktivieren",
                    isAvailable: user.isPremium || isInTrial,
                    isPremiumFeature: true
                )
                FeatureRow(
                    icon: "envelope.badge.fill",
                    title: "Terminabsage per Mail",
                    description: "Direkt aus der App absagen",
                    isAvailable: user.isPremium || isInTrial,
                    isPremiumFeature: true
                )
                FeatureRow(
                    icon: "calendar.badge.clock",
                    title: "Termine + Erinnerung",
                    description: "Nie wieder vergessen",
                    isAvailable: user.isPremium || isInTrial,
                    isPremiumFeature: true
                )
                FeatureRow(
                    icon: "map.fill",
                    title: "Navigation zur Praxis",
                    description: "Immer den richtigen Weg",
                    isAvailable: true,
                    isPremiumFeature: false
                )
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Fortschritt tracken",
                    description: "Deine Entwicklung sehen",
                    isAvailable: user.isPremium || isInTrial,
                    isPremiumFeature: true
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !user.isPremium {
                // UPGRADE BUTTON
                Button {
                    Task { await upgradeToPremium() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Upgrade zu Premium")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .cornerRadius(12)
                .disabled(isLoading)
                
                if let days = trialDaysRemaining {
                    Text("Du hast noch \(days) Tage kostenlosen Zugang")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                // BEREITS PREMIUM
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Du hast bereits Premium")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .foregroundStyle(.green)
                .cornerRadius(12)
            }
            
            Button {
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Schließen")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Upgrade Logic
    private func upgradeToPremium() async {
        isLoading = true
        
        // ⏳ Simuliert spätere StoreKit-Anfrage
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 Sekunde
        
        // ✅ Lokal setzen – später durch StoreKit ersetzen
        user.isPremium = true
        try? modelContext.save()
      
        
        isLoading = false
        dismiss()
    }
    /*
     // upgradeToPremium() – später:
     private func upgradeToPremium() async {
         isLoading = true
         
         // 🔄 StoreKit Purchase
         let success = await StoreKitManager.shared.purchase(.premium)
         
         if success {
             user.isPremium = true          // ← diese Zeile bleibt gleich!
             try? modelContext.save()
             authService.currentUser = user
         }
         
         isLoading = false
         dismiss()
     }
     
     */
}

// MARK: - FeatureRow
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isAvailable: Bool
    let isPremiumFeature: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isAvailable ? Color.accentColor : .gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(isAvailable ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // ✅ Rechte Seite
            VStack(spacing: 4) {
                Image(systemName: isAvailable ? "checkmark.circle.fill" : "lock.fill")
                    .foregroundStyle(isAvailable ? .green : .gray.opacity(0.4))
                
                // ✅ Immer Platz reservieren – unsichtbar wenn kein Premium Feature
                Text("PREMIUM")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(isPremiumFeature ? Color.yellow.opacity(0.2) : Color.clear)
                    .foregroundStyle(isPremiumFeature ? .orange : .clear)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .opacity(isAvailable ? 1.0 : 0.7)
    }
}
#Preview {
    let container = try! ModelContainer(
        for: User.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let mockUser = User(
        firstName: "Max",
        lastName: "Mustermann",
        email: "test@example.com",
        passwordHash: "hash",
        role: .patient,
        praxisId: nil
    )
    container.mainContext.insert(mockUser)
    
    return StatusEditSheet(user: mockUser)
        .modelContainer(container)
}
