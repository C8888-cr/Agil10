
import SwiftUI
import SwiftData
import MapKit
import UserNotifications


struct ProfileView: View {
    
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var authViewModel: AuthViewModel 
    @Environment(\.modelContext) var modelContext
    
    
    @Query var users: [User]
    @Query private var allAppointments: [Appointment]
    private var currentUser: User? {
        guard let userId = session.currentUser?.id else { return nil }
        return users.first { $0.id == userId }
    }
    
    @State private var isEditing = false
    @State private var showProfileHeaderEditSheet: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showProfileEditSheet = false
    @State private var showRoleEditSheet = false
    @State private var showEmailEditSheet = false
    @State private var showStatusEditSheet = false
    
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
                            // ✅ HEADER
                            ProfileHeaderCard(
                                user: user,
                                isEditing: $isEditing
                            )
                            .onTapGesture {
                                if isEditing {
                                    showProfileHeaderEditSheet = true
                                }
                            }
                            .sheet(isPresented: $showProfileHeaderEditSheet) {
                                ProfileHeaderEditSheet(user: user)
                            }
                            .padding(.top)
                            
                            InfoCard {
                                VStack(spacing: 0) {
                                    HStack {
                                        Label {
                                            Text("Berechtigungen")
                                                .foregroundStyle(.secondary)
                                        } icon: {
                                            Image(systemName: "shield.lefthalf.filled")
                                                .foregroundStyle(Color.accentColor.opacity(0.7))
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
                            }
                            .onTapGesture {
                                if isEditing {
                                    showRoleEditSheet = true
                                }
                            }
                            .sheet(isPresented: $showRoleEditSheet) {
                                RoleEditSheet(user: user)
                            }
                            // ✅ KONTAKT (ohne Title/Icon)
                            InfoCard {
                                VStack(spacing: 0) {
                                    HStack {
                                        Label {
                                            Text ("E-Mail")
                                                .foregroundStyle(.secondary)
                                        } icon: {
                                            Image(systemName: "envelope")
                                                .foregroundStyle(Color.accentColor.opacity(0.7))
                                        }
                                        Spacer ()
                                        
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
                            }
                            .onTapGesture {
                                if isEditing {
                                    showEmailEditSheet = true
                                }
                            }
                            .sheet(isPresented: $showEmailEditSheet) {
                                EmailEditSheet(user: user)
                            }
                            // ✅ PRAXIS
                            if let praxisId = praxisId,
                               let praxis = PraxisDataManager.shared.getPraxis(by: praxisId) {
                                
                                PraxisCard(
                                    user: user,
                                        praxis: praxis,
                                 
                                        isEditing: $isEditing
                                )
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
                            
                            InfoCard {
                                VStack(spacing: 0) {
                                    HStack {
                                        Label {
                                            Text("Status")
                                                .foregroundStyle(.secondary)
                                        } icon: {
                                            Image(systemName: user.isPremium ? "crown.fill" : "person",)
                                                .foregroundStyle(Color.accentColor.opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 8) {
                                            Text(user.isPremium ? "PREMIUM" : "Standard",)
                                                .fontWeight(.medium)
                                                .foregroundStyle(user.isPremium ? .yellow : .secondary)
                                            
                                            if isEditing {
                                                Image(systemName: "chevron.right")
                                                    .foregroundStyle(.gray)
                                                    .font(.subheadline)
                                            }
                                        }
                                    }
                                }
                                .onTapGesture {
                                    if isEditing {
                                        showStatusEditSheet = true
                                    }
                                }
                                .sheet(isPresented: $showStatusEditSheet) {
                                    StatusEditSheet(user: user)
                                }
                                Spacer()
                   
                
                                InfoRow(
                                    label: "Mitglied seit",
                                    value: user.createdAt.formatted(date: .abbreviated, time: .omitted),
                                    icon: "calendar"
                                )
                            }
                            
                            AppointmentReminderSection(
                                user: user,
                                appointments: allAppointments.filter { $0.userId == user.id }
                            )
                            
                            // ✅ BUTTONS
                            VStack(spacing: 12) {
                                if isEditing {
                                    Button {
                                        isEditing = false
                                    } label: {
                                        HStack {
                                            Image(systemName: "checkmark.circle")
                                            Text("Fertig")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray5))
                                        .foregroundStyle(.primary)
                                        .cornerRadius(12)
                                        
                                        
                                    }
                                  } else {
                                      Button {
                                          isEditing = true
                                      } label: {
                                          HStack {
                                              Image(systemName: "pencil.circle.fill")
                                              Text("Profil bearbeiten")
                                                  .fontWeight(.semibold)
                                          }
                                          .frame(maxWidth: .infinity)
                                          .padding()
                                          .background(Color.accentColor)
                                          .foregroundStyle(.white)
                                          .cornerRadius(12)
                                    }
                                }
                                
                                Button {
                                    Task {
                                        await authViewModel.signOut()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Abmelden")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .foregroundStyle(.red)
                                    .cornerRadius(12)
                                }
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
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                debugUserInDatabase()
            }
        }
    }
    
    // MARK: - Actions

    private func debugUserInDatabase() {
        guard let user = currentUser else { return }
        let userId = user.id
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { u in
                u.id == userId
            }
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

