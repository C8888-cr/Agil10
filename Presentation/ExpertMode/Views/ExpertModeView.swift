//
//  ExpertModeView.swift
//  Agil
//

import SwiftUI

struct ExpertModeView: View {
    @StateObject private var viewModel: ExpertModeViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        video: Video,
        tempoProtocol: TempoProtocol,
        weightKg: Int = 5,
        lastTrainingTotalKg: Int? = nil
    ) {
        _viewModel = StateObject(wrappedValue: ExpertModeViewModel(
            video: video,
            tempoProtocol: tempoProtocol,
            weightKg: weightKg,
            lastTrainingTotalKg: lastTrainingTotalKg
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                       colors: [
                           Color(red: 0.05, green: 0.05, blue: 0.07),
                           Color(red: 0.12, green: 0.12, blue: 0.14)
                       ],
                       startPoint: .top,
                       endPoint: .bottom
                   )
                   .ignoresSafeArea()

                ExpertModeContent(viewModel: viewModel) {
                    dismiss()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(viewModel.videoTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }
            }
        }
        .environment(\.colorScheme, .dark)  
        .presentationBackground(.black)        // ← NEU
    }
}

#Preview("ExpertModeView") {
    let video = Video(
        title: "Bizeps-Curls",
        videoFileName: "curls.mov",
        category: .strength,
        bodyRegion: .fullBody,
        equipment: .noEquipment,
        durationSeconds: 60,
        defaultRepetitions: 12,
        defaultPauseSeconds: 60,
        loopDurationSeconds: 60,
        rating: 0
    )
    let protocolModel = TempoProtocol(
        concentricSec: 2,
        holdSec: 0,
        eccentricSec: 3,
        sets: 3,
        reps: 12,
        restBetweenSetsSec: 60,
        subtype: .dynamic
    )

    return ExpertModeView(
        video: video,
        tempoProtocol: protocolModel,
        weightKg: 5,
        lastTrainingTotalKg: 180
    )
}
