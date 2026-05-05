import SwiftUI
import SwiftData
import MapKit
import UserNotifications

struct ProfileView: View {
    
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var themeManager: ThemeManager 
    
    @Query var users: [User]
    @Query private var allAppointments: [Appointment]
    
    private var currentUser: User? {
        guard let userId = session.currentUser?.id else { return nil }
        return users.first { $0.id == userId }
    }
    
    @State private var isEditing = false
    @State private var showProfileHeaderEditSheet = false
    @State private var selectedImage: UIImage?
    @State private var showProfileEditSheet = false
    @State private var showRoleEditSheet = false
    @State private var showEmailEditSheet = false
    @State private var showStatusEditSheet = false
    @State private var showResetAlert = false
    @State private var showDeleteAccountAlert = false
    
    private var praxisId: UUID? {
        currentUser?.praxisId
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        if let user = currentUser {
                            
                            // MARK: - Header
                            ProfileHeaderCard(user: user, isEditing: $isEditing)
                                .onTapGesture {
                                    if isEditing { showProfileHeaderEditSheet = true }
                                }
                                .sheet(isPresented: $showProfileHeaderEditSheet) {
                                    ProfileHeaderEditSheet(user: user)
                                }
                                .padding(.top)
                            
                            // MARK: - Berechtigungen
                            InfoCard {
                                HStack {
                                    Label {
                                        Text("Berechtigungen").foregroundStyle(.secondary)
                                    } icon: {
                                        Image(systemName: "shield.lefthalf.filled")
                                           .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.7))
                                    }
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Text(user.role.rawValue.capitalized)
                                            .fontWeight(.medium)
                                            .foregroundStyle(user.role == .admin ? .orange : .primary)
                                        if isEditing {
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.gray)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            }
                            .onTapGesture {
                                if isEditing { showRoleEditSheet = true }
                            }
                            .sheet(isPresented: $showRoleEditSheet) {
                                RoleEditSheet(user: user)
                            }
                            
                            // MARK: - E-Mail
                            InfoCard {
                                HStack {
                                    Label {
                                        Text("E-Mail").foregroundStyle(.secondary)
                                    } icon: {
                                        Image(systemName: "envelope")
                                            .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.7))
                                    }
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Text(user.email)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        if isEditing {
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.gray)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            }
                            .onTapGesture {
                                if isEditing { showEmailEditSheet = true }
                            }
                            .sheet(isPresented: $showEmailEditSheet) {
                                EmailEditSheet(user: user)
                            }
                            
                            // MARK: - Praxis
                            if let praxisId = praxisId,
                               let praxis = PraxisDataManager.shared.getPraxis(by: praxisId) {
                                PraxisCard(user: user, praxis: praxis, isEditing: $isEditing)
                            } else {
                                InfoCard {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundStyle(.orange)
                                        Text("Keine Praxis zugeordnet")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                }
                            }
                            
                            // MARK: - Status
                            InfoCard {
                                VStack(spacing: 0) {
                                    HStack {
                                        Label {
                                            Text("Status").foregroundStyle(.secondary)
                                        } icon: {
                                            Image(systemName: user.isPremium ? "crown.fill" : "person")
                                                .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.7))
                                        }
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Text(user.isPremium ? "PREMIUM" : "Standard")
                                                .fontWeight(.medium)
                                                .foregroundStyle(user.isPremium ? .yellow : .secondary)
                                            if isEditing {
                                                Image(systemName: "chevron.right")
                                                    .foregroundStyle(.gray)
                                                    .font(.subheadline)
                                            }
                                        }
                                    }
                                    .onTapGesture {
                                        if isEditing { showStatusEditSheet = true }
                                    }
                                    .sheet(isPresented: $showStatusEditSheet) {
                                        StatusEditSheet(user: user)
                                    }

                                    Divider().padding(.vertical, 8)

                                    InfoRow(
                                        label: "Mitglied seit",
                                        value: user.createdAt.formatted(date: .abbreviated, time: .omitted),
                                        icon: "calendar"
                                    )
                                }
                            }
                            
                            
                            // MARK: - Training / Expertenmodus

                            if user.preferences != nil {
                   
                                InfoCard {
                                    VStack(spacing: 0) {
                                        // Toggle: Expertenmodus an/aus
                                        HStack {
                                            Label {
                                                Text("Expertenmodus").foregroundStyle(.secondary)
                                            } icon: {
                                                Image(systemName: "dumbbell.fill")
                                                    .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.7))
                                            }
                                            Spacer()
                                 
                                                Toggle("", isOn: Binding(
                                                    get: {
                                                        let val = settingsVM.preferences.expertModeEnabled
                                                        print("📱 Toggle GET: \(val)")
                                                        return val
                                                    },
                                                    set: { newValue in
                                                        print("📱 Toggle SET: \(newValue)")
                                                        settingsVM.preferences.expertModeEnabled = newValue
                                                        print("📱 Nach SET: \(settingsVM.preferences.expertModeEnabled)")
                                                        try? settingsVM.modelContext.save()
                                                      //  settingsVM
                                             //   .objectWillChange.send()
                                                    }
                                                ))
                                                .labelsHidden()
                                        }
                                        
                                        if settingsVM.preferences.expertModeEnabled {
                                            Text("Bei Krafttraining wird der Trainingsmodus mit Tempo-Vorgabe und Gewichts-Tracking angezeigt.")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.top, 8)
                                            
                                            Divider().padding(.vertical, 12)
                                 /*
                                            HStack {
                                                Label {
                                                    Text("Video während Training").foregroundStyle(.secondary)
                                                } icon: {
                                                    Image(systemName: "play.rectangle")
                                                        .foregroundStyle(Color.accentColor.opacity(0.7))
                                                }
                                                Spacer()
                                                Picker("", selection: Binding(
                                                    get: { settingsVM.preferences.videoDuringTraining },
                                                    set: { newValue in
                                                        settingsVM.preferences.videoDuringTraining = newValue
                                                        try? settingsVM.modelContext.save()
                                                        settingsVM.objectWillChange.send()
                                                    }
                                                )) {
                                                    ForEach(VideoDuringTrainingMode.allCases) { mode in
                                                        Text(mode.displayName).tag(mode)
                                                    }
                                                }
                                                .labelsHidden()
                                                .pickerStyle(.menu)
                                  
                                  
                                            }
                                  */
                                        }
                                    }
                                }
                            }
                            
                            // MARK: - Farbe
                            InfoCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        Label {
                                            Text("Farbe").foregroundStyle(.secondary)
                                        } icon: {
                                            Image(systemName: "paintpalette.fill")
                                                .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.7))
                                        }
                                        Spacer()
                                    }
                                    
                                    HStack(spacing: 16) {
                                        ForEach(AppTheme.allCases) { theme in
                                            Button {
                                                themeManager.currentTheme = theme
                                            } label: {
                                                ZStack {
                                                    Circle()
                                                        .fill(theme.accentColor)
                                                        .frame(width: 36, height: 36)
                                                    
                                                    if themeManager.currentTheme == theme {
                                                        Circle()
                                                            .stroke(Color.primary, lineWidth: 2)
                                                            .frame(width: 44, height: 44)
                                                        
                                                        Image(systemName: "checkmark")
                                                            .foregroundStyle(.white)
                                                            .font(.system(size: 14, weight: .bold))
                                                    }
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            
                            
                            // MARK: - App Info
                            InfoCard {
                                VStack(spacing: 0) {
                                    HStack {
                                        Label {
                                            Text("Version").foregroundStyle(.secondary)
                                        } icon: {
                                            Image(systemName: "info.circle")
                                                .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.7))
                                        }
                                        Spacer()
                                        Text("1.0.0")
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                    }
                                    
                                    Divider().padding(.vertical, 8)
                                    
                                    HStack {
                                        Label {
                                            Text("Build").foregroundStyle(.secondary)
                                        } icon: {
                                            Image(systemName: "hammer")
                                                .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.7))
                                        }
                                        Spacer()
                                        Text("2025.01")
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            
                      
                            // MARK: - Buttons
                            VStack(spacing: 12) {
                                if isEditing {
                                    Button { isEditing = false } label: {
                                        Text("Fertig")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color(.systemGray5))
                                            .foregroundStyle(.primary)
                                            .cornerRadius(12)
                                    }
                                } else {
                                    Button { isEditing = true } label: {
                                        Text("Profil bearbeiten")
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(themeManager.currentTheme.accentColor.opacity(0.7))
                                            .foregroundStyle(.white)
                                            .cornerRadius(12)
                                    }
                                }
                                
                                Button {
                                    Task { await authViewModel.signOut() }
                                } label: {
                                    Text("Abmelden")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .foregroundStyle(.primary)
                                        .cornerRadius(12)
                                }
                                
                                HStack(spacing: 0) {
                                    Button { showResetAlert = true } label: {
                                        Text("Daten zurücksetzen")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity)
                                    }
                                    
                                    Divider().frame(height: 16)
                                    
                                    Button { showDeleteAccountAlert = true } label: {
                                        Text("Account löschen")
                                            .font(.footnote)
                                            .foregroundStyle(.red.opacity(0.7))
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                        } else {
                            ContentUnavailableView(
                                "Kein Profil",
                                systemImage: "person.circle.fill",
                                description: Text("Bitte einloggen, um dein Profil zu sehen.")
                            )
                        }
                    } // VStack
                } // ScrollView
            } // ZStack
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { debugUserInDatabase() }
            .alert("Alle Daten löschen?", isPresented: $showResetAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) { resetAllData() }
            } message: {
                Text("Alle Trainingsdaten und Einstellungen werden unwiderruflich gelöscht.")
            }
            .alert("Account wirklich löschen?", isPresented: $showDeleteAccountAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Account löschen", role: .destructive) { deleteAccount() }
            } message: {
                Text("Dein Account und alle Daten werden dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.")
            }
        } // NavigationStack
    }
    
    // MARK: - Actions
    
    private func deleteAccount() {
        Task { await authViewModel.deleteAccount() }
    }

    private func resetAllData() {
        Task { await authViewModel.resetAllData() }
    }
    
    private func debugUserInDatabase() {
        guard let user = currentUser else { return }
        let userId = user.id
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in u.id == userId }
        )
        if let dbUser = try? modelContext.fetch(descriptor).first {
            print("🔍 DEBUG User in DB:")
            print("   firstName: \(dbUser.firstName)")
            print("   lastName: \(dbUser.lastName)")
            print("   fullName: \(dbUser.fullName)")
            print("   praxisId: \(dbUser.praxisId?.uuidString ?? "nil")")
        } else {
            print("❌ User nicht in DB gefunden")
        }
    }
}
