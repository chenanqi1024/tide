//
//  AudioManager.swift
//  tide
//
//  Created by Codex on 2026/6/4.
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class AudioManager: ObservableObject {
    @Published private(set) var backgroundSoundID: String?
    @Published private(set) var isBackgroundPlaying = false
    @Published private(set) var isAlarmPlaying = false

    private var backgroundPlayer: AVQueuePlayer?
    private var backgroundLooper: AVPlayerLooper?
    private var alarmPlayer: AVQueuePlayer?
    private var alarmLooper: AVPlayerLooper?

    init() {
        configureAudioSession()
    }

    func playOrResume(_ sound: SoundItem) {
        if backgroundSoundID == sound.id, backgroundPlayer != nil {
            resumeBackground()
        } else {
            playLoopingSound(sound)
        }
    }

    func playLoopingSound(_ sound: SoundItem) {
        guard let url = URL(string: sound.url) else { return }
        configureAudioSession()
        stopBackground()

        let player = AVQueuePlayer()
        let item = AVPlayerItem(url: url)
        backgroundLooper = AVPlayerLooper(player: player, templateItem: item)
        backgroundPlayer = player
        backgroundSoundID = sound.id
        isBackgroundPlaying = true
        player.play()
    }

    func pauseBackground() {
        backgroundPlayer?.pause()
        isBackgroundPlaying = false
    }

    func resumeBackground() {
        configureAudioSession()
        backgroundPlayer?.play()
        isBackgroundPlaying = backgroundPlayer != nil
    }

    func stopBackground() {
        backgroundPlayer?.pause()
        backgroundPlayer?.removeAllItems()
        backgroundPlayer = nil
        backgroundLooper = nil
        backgroundSoundID = nil
        isBackgroundPlaying = false
    }

    func playAlarm(_ alarm: SoundItem) {
        guard let url = URL(string: alarm.url) else { return }
        configureAudioSession()
        stopAlarm()

        let player = AVQueuePlayer()
        let item = AVPlayerItem(url: url)
        alarmLooper = AVPlayerLooper(player: player, templateItem: item)
        alarmPlayer = player
        isAlarmPlaying = true
        player.play()
    }

    func stopAlarm() {
        alarmPlayer?.pause()
        alarmPlayer?.removeAllItems()
        alarmPlayer = nil
        alarmLooper = nil
        isAlarmPlaying = false
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio should not block the rest of the app experience.
        }
    }
}
