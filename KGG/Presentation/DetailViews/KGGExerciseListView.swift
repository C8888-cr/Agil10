// PASTE TO: Agil/KGG/Presentation/DetailViews/KGGExerciseListView.swift (REPLACE)

//
//  KGGExerciseListView.swift
//  Agil
//
//  Zeigt gescannte KGG-Übungen in Read-Only-Liste.
//  Schalter hier legt fest, ob im Player anschließend das Video sichtbar ist.
//

import SwiftUI
import AgilCore

struct KGGExerciseListView: View {

    @StateObject private var viewModel: KGGListViewModel
    @State private var showScanner = false
    @State private var selectedExercise: KGGScannedExercise?

    private let repository: KGGExerciseRepository

    init(repository: KGGExerciseRepository, warmupRepository: KGGWarmupRepository) {
          self.repository = repository
          _viewModel = StateObject(wrappedValue: KGGListViewModel(repository: repository, warmupRepository: warmupRepository))
      }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 16) {
             
                // Content
                contentView
            }

            if let error = viewModel.error {
                            errorBanner(error)
                        }
                        
                        if viewModel.showAssignmentConfirmation {
                            assignmentConfirmationBanner
                        }
                    }
        .sheet(isPresented: $showScanner) {
            QRScannerView { qrString in
                viewModel.handleQRCodeScanned(qrString)
            }
        }
        .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showScanner = true
                        } label: {
                            Image(systemName: "qrcode")
                                .resizable()
                                .scaledToFit()
                                .padding(6)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                    }
                }
                .sheet(isPresented: $showScanner) {
                    QRScannerView { qrString in
                        viewModel.handleQRCodeScanned(qrString)
                    }
                }
        
        
        
        .fullScreenCover(item: $selectedExercise) { exercise in
                    if let video = createVideoForExercise(exercise) {
                        KGGExercisePlayerView(
                            exercise: exercise,
                            video: video,
                            // Video läuft nur noch im Intro (KGGExercisePlayerView.introVideoOverlay).
                            // Während der Pille wird es nie angezeigt — fest deaktiviert.
                            isVideoVisible: false,
                            repository: repository,
                            onComplete: {
                                selectedExercise = nil
                                viewModel.completeExercise(exercise.id)
                            }
                        )
                    }
                }
        .onAppear {
            viewModel.visibilityManager.checkExistingSession()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.visibilityState {
        case .noKGG:
            noKGGPlaceholder

        case .visible:
                   if viewModel.isLoading {
                       ProgressView()
                           .frame(maxHeight: .infinity, alignment: .center)
                   } else if viewModel.visibleExercises.isEmpty && viewModel.visibleWarmups.isEmpty {
                       emptyState
                   } else {
                       VStack(spacing: 12) {
                           if !viewModel.visibleWarmups.isEmpty {
                               warmupSection
                           }
                           exercisesList
                       }
                   }
        case .completed:
            KGGCompletionView()
        }
    }

    private var noKGGPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Keine aktive KGG")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Scanne einen QR-Code um zu starten")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(32)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("Videos werden heruntergeladen...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView()
        }
        .padding(40)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private var assignmentConfirmationBanner: some View {
            VStack {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(viewModel.assignmentConfirmationMessage)
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(12)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(16)

                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.25), value: viewModel.showAssignmentConfirmation)
        }

    private var exercisesList: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(viewModel.visibleExercises.count) Übungen")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                if viewModel.timeRemainingSeconds > 0 {
                    let minutes = viewModel.timeRemainingSeconds / 60
                    let seconds = viewModel.timeRemainingSeconds % 60
                    Text(String(format: "%d:%02d", minutes, seconds))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.visibleExercises) { exercise in
                        exerciseRow(exercise)
                            .onTapGesture {
                                selectedExercise = exercise
                            }
                    }
                }
                .padding(16)
            }
        }
    }
    
    private var warmupSection: some View {
          VStack(alignment: .leading, spacing: 8) {
              Text("Aufwärmen")
                  .font(.caption.weight(.medium))
                  .foregroundStyle(.secondary)
                  .padding(.horizontal, 16)

              VStack(spacing: 8) {
                  ForEach(viewModel.visibleWarmups) { warmup in
                      warmupRow(warmup)
                  }
              }
              .padding(.horizontal, 16)
          }
      }

      private func warmupRow(_ warmup: KGGScannedWarmup) -> some View {
          VStack(alignment: .leading, spacing: 4) {
              Text(warmup.type)
                  .font(.subheadline.weight(.semibold))
                  .foregroundStyle(.primary)
              Text(warmup.displayText)
                  .font(.caption)
                  .foregroundStyle(.secondary)
          }
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.systemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 10))
      }


    private func exerciseRow(_ exercise: KGGScannedExercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.exerciseTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                Label("\(exercise.sets)×\(exercise.reps)", systemImage: "repeat")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(Int(exercise.weightKg))kg", systemImage: "scalemass")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(String(format: "%d:%02d", exercise.estimatedTotalDurationSec / 60, exercise.estimatedTotalDurationSec % 60), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func errorBanner(_ error: String) -> some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.primary)
                Spacer()
                Button { viewModel.clearError() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(16)

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func createVideoForExercise(_ exercise: KGGScannedExercise) -> Video? {
        Video(
            id: exercise.exerciseId,
            title: exercise.exerciseTitle,
            videoFileName: exercise.videoFileName,
            category: .strength,
            bodyRegion: .fullBody,
            equipment: .noEquipment,
            durationSeconds: exercise.estimatedTotalDurationSec,
            rating: 0
        )
    }
}
