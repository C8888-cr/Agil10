//
//  PraxisSelectionSheet.swift
//  Agil10.0
//
//  Created by Christiane Roth on 18.02.26.
//
import SwiftUI
import SwiftData



struct PraxisSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var authService: AuthService
    
    let user: User
    @State private var selectedPraxisId: UUID?
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var praxisList: [Praxis] {
        PraxisDataManager.shared.praxen
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 8) {
                    // ✅ TITLE
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Praxis wählen")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top)
                    }
                    
                    // ✅ SCROLLABLE CONTENT
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(praxisList, id: \.id) { praxis in
                                ZStack(alignment: .topTrailing) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Name
                                        Text(praxis.name)
                                            .font(.title3.bold())
                                            .foregroundStyle(Color.accentColor)
                                        
                                        // Adresse
                                        if let address = praxis.fullAddress {
                                            HStack(spacing: 8) {
                                                Text(address)
                                                    .font(.subheadline)
                                                Spacer()
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundStyle(.accent)
                                                    .font(.subheadline)
                                            }
                                        }
                                        
                                        Divider()
                                        
                                        // Kontaktinfos
                                        if let telefon = praxis.telefon {
                                            HStack(spacing: 8) {
                                                Text(telefon)
                                                    .font(.subheadline)
                                                Spacer()
                                                
                                                Link(destination: URL(string: "tel://\(telefon.filter { $0.isNumber })")!) {
                                                    Image(systemName: "phone.circle.fill")
                                                        .foregroundStyle(.accent)
                                                        .font(.subheadline)
                                                }
                                            }
                                        }
                                        if let email = praxis.email {
                                            HStack(spacing: 8) {
                                                Text(email)
                                                    .font(.subheadline)
                                                Spacer()
                                                
                                                Link(destination: URL(string: "mailto:\(email)")!) {
                                                    Image(systemName: "envelope.circle.fill")
                                                        .foregroundStyle(.accent)
                                                        .font(.subheadline)
                                                }
                                            }
                                        }
                                    }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)
                                        
                                        // ✅ CHECKMARK
                                        if selectedPraxisId == praxis.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.accentColor)
                                                .font(.title3)
                                                .padding(12)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedPraxisId = praxis.id
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        // ✅ BUTTONS (am unteren Rand)
                        VStack(spacing: 12) {
                            Button {
                                saveSelection()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Speichern")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedPraxisId != nil ? Color.accentColor : Color.gray.opacity(0.5))
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                            }
                            .disabled(selectedPraxisId == nil || isSaving)
                            
                            Button {
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Abbrechen")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundStyle(.primary)
                                .cornerRadius(12)
                            }
                            .disabled(isSaving)
                        }
                        .padding()
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .alert("Fehler", isPresented: .constant(errorMessage != nil)) {
                    Button("OK") { errorMessage = nil }
                } message: {
                    Text(errorMessage ?? "")
                }
            }
        }
    
    // MARK: - Actions
    private func saveSelection() {
        guard let praxisId = selectedPraxisId else { return }
        
        isSaving = true
        
        // Update User in SwiftData
        user.praxisId = praxisId
        
        do {
            try modelContext.save()
            
            // Update auch in AuthService
            authService.currentUser?.praxisId = praxisId
            
            print("✅ Praxis gespeichert: \(PraxisDataManager.shared.getPraxisName(for: praxisId))")
            dismiss()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
            print("❌ Fehler: \(error)")
        }
        
        isSaving = false
    }
}
#Preview {
    let mockContainer = try! ModelContainer(
        for: User.self
    )
    let mockContext = ModelContext(mockContainer)
    
    let mockAuthService = MockAuthService(modelContext: mockContext)
    
    // ✅ Therapist User
    let therapistUser = User(
        id: MockAuthService.mockTherapistId,
        firstName: "Christiane",
        lastName: "Roth",
        email: "therapist@agil.de",
        passwordHash: "",
        role: .therapist,
        praxisId: PraxisDataManager.praxis1Id
    )
    
    PraxisSelectionSheet(user: therapistUser)
        .environmentObject(mockAuthService)
        .modelContainer(mockContainer)
}
