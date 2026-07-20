//
//  PraxisCard.swift
//  Agil10.0
//
//  Created by Christiane Roth on 12.04.26.
//
import SwiftUI
import SwiftData
import MapKit
import UserNotifications
import AgilCore

struct PraxisCard: View {
    @Bindable var user: User
    let praxis: Praxis
    @Binding var isEditing: Bool
    @State private var showPraxisSelectionSheet = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                // Name mit Pfeil
                ZStack(alignment: .leading) {
                    Text(praxis.name)
                        .font(.title3.bold())
                        .foregroundStyle( themeManager.currentTheme.accentColor)
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
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "")
                                .foregroundStyle(.green)
                            Text(address)
                                .font(.subheadline)
                            
                            
                            Spacer()
                            
                            Button(action: {
                                praxis.openInMaps()
                            }) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle( themeManager.currentTheme.accentColor)
                                    .font(.title3)
                            }
                        }
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
                                .foregroundStyle( themeManager.currentTheme.accentColor)
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
                                .foregroundStyle( themeManager.currentTheme.accentColor)
                                .font(.title3)
                        }
                    }
                }
            }
        }
        .onTapGesture {
            if isEditing {
                showPraxisSelectionSheet = true
            }
        }
        .sheet(isPresented: $showPraxisSelectionSheet) {
            PraxisSelectionSheet(user: user)
        }
    }
}
