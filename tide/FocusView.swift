//
//  FocusView.swift
//  tide
//
//  Created by Codex on 2026/6/4.
//

import Combine
import SwiftUI

enum FocusStage: String {
    case focus = "专注"
    case rest = "休息"
}

enum FocusMode: String, CaseIterable, Identifiable {
    case short
    case long

    var id: String { rawValue }

    var title: String {
        switch self {
        case .short: "25 / 5"
        case .long: "50 / 10"
        }
    }

    var focusDuration: Int {
        switch self {
        case .short: 25 * 60
        case .long: 50 * 60
        }
    }

    var restDuration: Int {
        switch self {
        case .short: 5 * 60
        case .long: 10 * 60
        }
    }
}

@MainActor
final class FocusTimerViewModel: ObservableObject {
    @Published var mode: FocusMode = .short
    @Published var stage: FocusStage = .focus
    @Published var remainingSeconds = FocusMode.short.focusDuration
    @Published var isRunning = false
    @Published var hasStarted = false
    @Published var immersiveMode = false
    @Published var selectedSoundID: String?
    @Published var showingFailure = false

    private var timerTask: Task<Void, Never>?
    private var currentSound: SoundItem?

    var remainingText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func changeMode(to newMode: FocusMode, audioManager: AudioManager) {
        mode = newMode
        end(audioManager: audioManager)
    }

    func start(audioManager: AudioManager, selectedSound: SoundItem?) {
        currentSound = selectedSound
        isRunning = true
        hasStarted = true

        if stage == .focus, let selectedSound {
            audioManager.playLoopingSound(selectedSound)
        }

        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                tick(audioManager: audioManager)
            }
        }
    }

    func pause(audioManager: AudioManager) {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        audioManager.stopBackground()
    }

    func end(audioManager: AudioManager) {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        hasStarted = false
        stage = .focus
        remainingSeconds = mode.focusDuration
        audioManager.stopBackground()
    }

    func updateSelectedSound(_ sound: SoundItem?, audioManager: AudioManager) {
        currentSound = sound
        guard isRunning, stage == .focus else { return }

        if let sound {
            audioManager.playLoopingSound(sound)
        } else {
            audioManager.stopBackground()
        }
    }

    func handleAppEnteredBackground(audioManager: AudioManager) {
        guard immersiveMode, isRunning, stage == .focus else { return }
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        hasStarted = false
        stage = .focus
        remainingSeconds = mode.focusDuration
        audioManager.stopBackground()
        showingFailure = true
    }

    private func tick(audioManager: AudioManager) {
        guard isRunning else { return }

        if remainingSeconds > 1 {
            remainingSeconds -= 1
        } else {
            advanceStage(audioManager: audioManager)
        }
    }

    private func advanceStage(audioManager: AudioManager) {
        switch stage {
        case .focus:
            stage = .rest
            remainingSeconds = mode.restDuration
            audioManager.stopBackground()
        case .rest:
            stage = .focus
            remainingSeconds = mode.focusDuration
            if let currentSound {
                audioManager.playLoopingSound(currentSound)
            }
        }
    }

    deinit {
        timerTask?.cancel()
    }
}

struct FocusView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var library: SoundLibrary
    @EnvironmentObject private var audioManager: AudioManager
    @StateObject private var viewModel = FocusTimerViewModel()

    private var selectedSound: SoundItem? {
        library.sounds.first { $0.id == viewModel.selectedSoundID }
    }

    var body: some View {
        NavigationStack {
            Group {
                if library.isLoading, library.sounds.isEmpty {
                    LoadingRetryView(isLoading: true, message: nil) {
                        Task { await library.load() }
                    }
                } else if let errorMessage = library.errorMessage, library.sounds.isEmpty {
                    LoadingRetryView(isLoading: false, message: errorMessage) {
                        Task { await library.load() }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            timerPanel
                            soundPanel
                            immersivePanel
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("专注")
        }
        .task {
            await library.loadIfNeeded()
            if viewModel.selectedSoundID == nil {
                viewModel.selectedSoundID = library.sounds.first?.id
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                viewModel.handleAppEnteredBackground(audioManager: audioManager)
            }
        }
        .onChange(of: viewModel.selectedSoundID) { _, _ in
            viewModel.updateSelectedSound(selectedSound, audioManager: audioManager)
        }
        .alert("本次专注失败", isPresented: $viewModel.showingFailure) {
            Button("知道了") {}
        } message: {
            Text("沉浸模式下，专注期间进入后台会结束本次计时。")
        }
    }

    private var timerPanel: some View {
        VStack(spacing: 18) {
            Picker("模式", selection: Binding(
                get: { viewModel.mode },
                set: { viewModel.changeMode(to: $0, audioManager: audioManager) }
            )) {
                ForEach(FocusMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(viewModel.stage.rawValue)
                .font(.headline)
                .foregroundStyle(viewModel.stage == .focus ? .primary : .secondary)

            Text(viewModel.remainingText)
                .font(.system(size: 64, weight: .semibold, design: .rounded).monospacedDigit())

            HStack(spacing: 12) {
                Button {
                    if viewModel.isRunning {
                        viewModel.pause(audioManager: audioManager)
                    } else {
                        viewModel.start(audioManager: audioManager, selectedSound: selectedSound)
                    }
                } label: {
                    Label(viewModel.isRunning ? "暂停" : (viewModel.hasStarted ? "继续" : "开始"),
                          systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.end(audioManager: audioManager)
                } label: {
                    Label("结束", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var soundPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("背景音")
                .font(.headline)

            Picker("背景音", selection: $viewModel.selectedSoundID) {
                Text("不播放").tag(nil as String?)
                ForEach(library.sounds) { sound in
                    Text(sound.name).tag(sound.id as String?)
                }
            }
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var immersivePanel: some View {
        Toggle(isOn: $viewModel.immersiveMode) {
            VStack(alignment: .leading, spacing: 4) {
                Text("沉浸模式")
                    .font(.headline)
                Text("开启后，专注期间进入后台会判定失败。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
