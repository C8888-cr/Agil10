//
//  KGGTherapistTabView.swift
//  AgilKGG
//
//  Hauptcontainer für Therapeuten-App.
//  Tab-Navigation: Patienten → Videos → Übungen → QR
//

import SwiftUI
import SwiftData
import AgilCore

struct KGGTherapistTabView: View {
    @StateObject private var viewModel: KGGTherapistViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab: Tab = .patients
    
    enum Tab {
        case patients
        case videos
        case exercises
        case qrGenerator
    }
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: KGGTherapistViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Patienten-Verwaltung
            PatientManagementView()
                .tabItem {
                    Label("Patienten", systemImage: "person.badge.plus")
                }
                .tag(Tab.patients)
            
            // Tab 2: Video-Auswahl
            VideoSelectionView()
                .tabItem {
                    Label("Videos", systemImage: "film")
                }
                .tag(Tab.videos)
                .disabled(viewModel.selectedPatient == nil)
            
            // Tab 3: Übungs-Konfiguration
            ExerciseConfigView()
                .tabItem {
                    Label("Einstellungen", systemImage: "slider.horizontal.3")
                }
                .tag(Tab.exercises)
                .disabled(viewModel.selectedPatient == nil)
            
            // Tab 4: QR-Generator
            QRGeneratorView()
                .tabItem {
                    Label("QR-Code", systemImage: "qrcode")
                }
                .tag(Tab.qrGenerator)
                .disabled(viewModel.selectedPatient == nil)
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KGGPatient.self, configurations: config)
    
    KGGTherapistTabView(modelContext: container.mainContext)
        .environment(\.modelContext, container.mainContext)
}
