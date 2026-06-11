//
//  BreatheView.swift
//  tide
//
//  Created by Codex on 2026/6/4.
//

import Combine
import SwiftUI

@MainActor
final class BreathingTrainingViewModel: ObservableObject {
    @Published var currentStepIndex = 0
    @Published var remainingSeconds: Int
    @Published var elapsedSeconds = 0
    @Published var isRunning = false

    let exercise: BreathingExercise
    private var timerTask: Task<Void, Never>?

    init(exercise: BreathingExercise) {
        self.exercise = exercise
        remainingSeconds = exercise.steps.first?.seconds ?? 0
    }

    var currentStep: BreathingStep {
        exercise.steps[currentStepIndex]
    }

    var elapsedText: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var circleScale: CGFloat {
        let duration = max(1, currentStep.seconds)
        let remaining = max(0, remainingSeconds)

        switch currentStep.kind {
        case .inhale:
            let progress = 1 - CGFloat(remaining) / CGFloat(duration)
            return 0.65 + progress * 0.35
        case .exhale:
            let progress = CGFloat(remaining) / CGFloat(duration)
            return 0.65 + progress * 0.35
        case .hold:
            return previousStepKind == .inhale ? 1 : 0.65
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                tick()
            }
        }
    }

    func pause() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    func end() {
        pause()
        currentStepIndex = 0
        remainingSeconds = exercise.steps.first?.seconds ?? 0
        elapsedSeconds = 0
    }

    private func tick() {
        guard isRunning else { return }

        elapsedSeconds += 1
        if remainingSeconds > 1 {
            remainingSeconds -= 1
        } else {
            advanceStep()
        }
    }

    private func advanceStep() {
        currentStepIndex = (currentStepIndex + 1) % exercise.steps.count
        remainingSeconds = currentStep.seconds
    }

    private var previousStepKind: BreathingPhase {
        let previousIndex = currentStepIndex == 0 ? exercise.steps.count - 1 : currentStepIndex - 1
        return exercise.steps[previousIndex].kind
    }

    deinit {
        timerTask?.cancel()
    }
}

struct BreatheView: View {
    var body: some View {
        NavigationStack {
            List(AppData.breathingExercises) { exercise in
                NavigationLink {
                    BreathingTrainingView(exercise: exercise)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.title)
                            .font(.headline)
                        Text(exercise.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("呼吸")
        }
    }
}

struct BreathingTrainingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BreathingTrainingViewModel

    init(exercise: BreathingExercise) {
        _viewModel = StateObject(wrappedValue: BreathingTrainingViewModel(exercise: exercise))
    }

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text(viewModel.exercise.title)
                    .font(.title2.weight(.semibold))
                Text(viewModel.currentStep.kind.rawValue)
                    .font(.largeTitle.weight(.bold))
            }

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.75), Color.blue.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220 * viewModel.circleScale, height: 220 * viewModel.circleScale)
                    .shadow(color: .blue.opacity(0.25), radius: 18, y: 8)
                    .animation(.linear(duration: 1), value: viewModel.remainingSeconds)
                    .animation(.linear(duration: 1), value: viewModel.currentStepIndex)

                Text("\(viewModel.remainingSeconds)")
                    .font(.system(size: 56, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .frame(width: 260, height: 260)

            Label("已进行 \(viewModel.elapsedText)", systemImage: "clock")
                .font(.headline.monospacedDigit())

            HStack(spacing: 12) {
                Button {
                    viewModel.isRunning ? viewModel.pause() : viewModel.start()
                } label: {
                    Label(viewModel.isRunning ? "暂停" : "开始",
                          systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.end()
                    dismiss()
                } label: {
                    Label("结束", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 32)
        .padding(.horizontal, 20)
        .navigationTitle("训练")
        .navigationBarTitleDisplayMode(.inline)
    }
}
