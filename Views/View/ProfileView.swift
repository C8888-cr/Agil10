
import SwiftUI
import SwiftData
struct ProfileView: View {
    
    @EnvironmentObject var authService: AuthService
    @Environment(\.modelContext) var modelContext
    private var currentUser: User? { authService.currentUser }
    
    @State private var isEditing = false
    @State private var showProfileHeaderEditSheet: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showProfileEditSheet = false
    @State private var showRoleEditSheet = false
    
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
                                                               // NavigationLink oder Sheet öffnen
                                                           }
                                                       }
                            
                            
                            
                            // ✅ ROLLE
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
                                                               // NavigationLink oder Sheet öffnen
                                                           }
                                                       }
                            // ✅ PRAXIS
                            if let praxisId = praxisId,
                               let praxis = PraxisDataManager.shared.getPraxis(by: praxisId) {
                                
                                PraxisCard(praxis: praxis,
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
                                                                   // NavigationLink oder Sheet öffnen
                                                               }
                                                           }
                                Spacer()
                   
                
                                InfoRow(
                                    label: "Mitglied seit",
                                    value: user.createdAt.formatted(date: .abbreviated, time: .omitted),
                                    icon: "calendar"
                                )
                            }
                            
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
                                        await authService.logout()
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
// MARK: - ProfileHeaderCard
struct ProfileHeaderCard: View {
    let user: User
    @Binding var isEditing: Bool

    
    var body: some View {
        VStack(spacing: 16) {
            // ✅ AVATAR mit ACCENT COLOR
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.3),
                                Color.accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 10)
                
                // ✅ BILD ODER INITIALEN
                               if let imageData = user.profileImage,
                                  let uiImage = UIImage(data: imageData) {
                                   Image(uiImage: uiImage)
                                       .resizable()
                                       .scaledToFill()
                                       .frame(width: 100, height: 100)
                                       .clipShape(Circle())
                               } else {
                                   Text(user.initials)
                                       .font(.system(size: 36, weight: .bold, design: .rounded))
                                       .foregroundStyle(Color.accentColor)
                               }
                           }
            // ✅ NAME mit PFEIL
            ZStack {
                
                VStack(spacing: 4) {
                    Text(user.fullName)
                        .font(.title2.bold())
                    
                    if let age = user.age {
                        Text("\(age) Jahre")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if isEditing {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
        .padding(.horizontal)
    }
}
// MARK: - InfoCard

struct InfoCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
        .padding(.horizontal)
    }
}
// MARK: - InfoRow
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Label {
                Text(label)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor.opacity(0.7))
            }
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
    }
}
// MARK: - PraxisCard
struct PraxisCard: View {
    let praxis: Praxis
    @Binding var isEditing: Bool
    
    
    var body: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                // Name mit Pfeil
                ZStack(alignment: .leading) {
                    Text(praxis.name)
                        .font(.title3.bold())
                        .foregroundStyle(Color.accentColor)
                    if isEditing {
                        HStack {
                            Spacer()
                            Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                                        .font(.subheadline)
                        }
                    }
                }

                // Adresse
                if let address = praxis.fullAddress {
                    Label {
                        Text(address)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "")
                            .foregroundStyle(.red)
                    }
                }
                
                Divider()
                
                // Kontakte
                if let telefon = praxis.telefon {
                    HStack {
                        Image(systemName: "")
                            .foregroundStyle(.green)
                        Text(telefon)
                            .font(.subheadline)
                        Spacer()
                        
                        Button {
                            if let url = URL(string: "tel://\(telefon.filter { $0.isNumber })") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image(systemName: "phone.circle.fill")
                                .foregroundStyle(Color.accentColor)
                                .font(.title3)
                        }
                    }
                }
                
                if let email = praxis.email {
                    HStack {
                        Image(systemName: "")
                            .foregroundStyle(.blue)
                        Text(email)
                            .font(.subheadline)
                        Spacer()
                        
                        Button {
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image(systemName: "envelope.circle.fill")
                                .foregroundStyle(Color.accentColor)
                                .font(.title3)
                        }
                    }
                }
            }
        }
    }
}
