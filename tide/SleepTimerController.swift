//
//  SleepTimerController.swift
//  tide
//
//  Created by Codex on 2026/6/4.
//

import Combine
import Foundation

@MainActor
final class SleepTimerController: ObservableObject {
    @Published var wakeSelection = Date()
    @Published var targetDate: Date?
    @Published var remainingText = "--:--:--"
    @Published var isCountingDown = false
    @Published var showingAlarm = false

    private var countdownTask: Task<Void, Never>?
    private var alarmLimitTask: Task<Void, Never>?
    private var audioManager: AudioManager?
    private var alarmSound: SoundItem?

    func start(alarm: SoundItem?, audioManager: AudioManager) {
        self.audioManager = audioManager
        alarmSound = alarm
        targetDate = nextWakeDate(from: wakeSelection)
        isCountingDown = true
        showingAlarm = false
        alarmLimitTask?.cancel()
        countdownTask?.cancel()
        updateRemainingText()

        countdownTask = Task { @MainActor in
            while !Task.isCancelled {
                guard let targetDate else { return }
                if Date() >= targetDate {
                    fireAlarm()
                    return
                }

                updateRemainingText()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        targetDate = nil
        isCountingDown = false
        remainingText = "--:--:--"
    }

    func stopAlarm() {
        finishAlarmFlow()
    }

    private func fireAlarm() {
        countdownTask?.cancel()
        countdownTask = nil
        isCountingDown = false
        remainingText = "00:00:00"
        audioManager?.stopBackground()

        if let alarmSound {
            audioManager?.playAlarm(alarmSound)
        }

        showingAlarm = true
        alarmLimitTask?.cancel()
        alarmLimitTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 20 * 60 * 1_000_000_000)
            finishAlarmFlow()
        }
    }

    private func finishAlarmFlow() {
        alarmLimitTask?.cancel()
        alarmLimitTask = nil
        audioManager?.stopAlarm()
        targetDate = nil
        isCountingDown = false
        showingAlarm = false
        remainingText = "--:--:--"
    }

    private func nextWakeDate(from selectedDate: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedDate)
        return calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: components.hour, minute: components.minute),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(24 * 60 * 60)
    }

    private func updateRemainingText() {
        guard let targetDate else {
            remainingText = "--:--:--"
            return
        }

        let remaining = max(0, Int(targetDate.timeIntervalSinceNow.rounded(.up)))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        remainingText = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    deinit {
        countdownTask?.cancel()
        alarmLimitTask?.cancel()
    }
}
