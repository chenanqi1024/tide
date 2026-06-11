//
//  SleepView.swift
//  tide
//
//  Created by Codex on 2026/6/4.
//

import SwiftUI

struct SleepView: View {
    @EnvironmentObject private var library: SoundLibrary

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

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
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(library.sounds) { sound in
                                NavigationLink {
                                    SleepPlayerView(sound: sound)
                                } label: {
                                    SoundCardView(sound: sound)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                    .refreshable {
                        await library.load()
                    }
                }
            }
            .navigationTitle("睡眠")
        }
        .task {
            await library.loadIfNeeded()
        }
    }
}

struct SleepPlayerView: View {
    let sound: SoundItem

    @EnvironmentObject private var library: SoundLibrary
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var sleepTimer: SleepTimerController

    private var isCurrentSoundPlaying: Bool {
        audioManager.backgroundSoundID == sound.id && audioManager.isBackgroundPlaying
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                CoverImageView(urlString: sound.cover, title: sound.name)
                    .frame(width: 260, height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(radius: 12, y: 6)
                    .padding(.top, 24)

                Text(sound.name)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Button {
                    if isCurrentSoundPlaying {
                        audioManager.pauseBackground()
                    } else {
                        audioManager.playOrResume(sound)
                    }
                } label: {
                    Image(systemName: isCurrentSoundPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 68, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isCurrentSoundPlaying ? "暂停" : "播放")

                sleepTimerSection
            }
            .padding(20)
        }
        .navigationTitle("播放")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sleepTimerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("睡眠定时")
                .font(.headline)

            DatePicker("醒来时间", selection: $sleepTimer.wakeSelection, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)

            if sleepTimer.isCountingDown {
                HStack {
                    Label(sleepTimer.remainingText, systemImage: "clock")
                        .font(.title3.monospacedDigit())
                    Spacer()
                    Button("取消定时") {
                        sleepTimer.cancelCountdown()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Button {
                sleepTimer.start(alarm: library.alarm, audioManager: audioManager)
            } label: {
                Label("按醒来时间开始", systemImage: "alarm.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
