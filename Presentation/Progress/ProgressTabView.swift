//
//  WeeklyProgressView.swift
//  Agil5.0
//
//  Migrated to SwiftData Architecture
//
import SwiftUI
import SwiftData


struct ProgressTabView: View {
    @EnvironmentObject var progressVM: ProgressViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var activeSheet: SheetType?
    @EnvironmentObject var themeManager: ThemeManager

    enum SheetType: Identifiable {
        case
        profile
        var id: Self { self }
    }

    
    var body: some View {
      
            ScrollView {
                VStack(spacing: 24) {
                    // 🎯 Wochenübersicht mit schönen Balken
                    WeeklyProgressCard()
                    
                    // 📊 Exercise Type Breakdown
                    ExerciseTypeStatsCard()
                    
                    // 📅 Tägliche Aufschlüsselung
           //         DailyBreakdownCard()
                    
                    // 📈 Gesamtstatistiken
                    OverallStatisticsCard()
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
               
                        Button {
                            activeSheet = .profile
                 
                    } label: {
                        // ✅ PROFILBILD STATT ICON
                                   if let user = session.currentUser,
                                      let imageData = user.profileImage,
                                      let uiImage = UIImage(data: imageData) {
                                       Image(uiImage: uiImage)
                                           .resizable()
                                           .scaledToFill()
                                           .frame(width: 35, height: 35)
                                           .clipShape(Circle())
                                   } else {
                                       Circle()
                                           .fill(themeManager.currentTheme.accentColor.opacity(0.3))
                                           .frame(width: 35, height: 35)
                                           .overlay(
                                               Text(session.currentUser?.initials ?? "?")
                                                   .font(.system(size: 14, weight: .bold))
                                                   .foregroundStyle(themeManager.currentTheme.accentColor)
                                           )
                                   }
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {

                case .profile:
                    ProfileView()
                        .environmentObject(session)
                        .environment(\.modelContext, profileVM.modelContext)
                }
            }
            .onAppear {
                guard let user = session.currentUser else { return }
                progressVM.calculateAllProgress(for: user)
            }
        }
    }


struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}




