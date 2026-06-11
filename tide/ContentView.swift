//
//  ContentView.swift
//  tide
//
//  Created by chenanqi on 2026/6/4.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var soundLibrary = SoundLibrary()
    @StateObject private var audioManager = AudioManager()
    @StateObject private var sleepTimer = SleepTimerController()

    var body: some View {
        TabView {
            SleepView()
                .tabItem {
                    Label("睡眠", systemImage: "moon.zzz.fill")
                }

            FocusView()
                .tabItem {
                    Label("专注", systemImage: "timer")
                }

            BreatheView()
                .tabItem {
                    Label("呼吸", systemImage: "wind")
                }

            MeditateView()
                .tabItem {
                    Label("冥想", systemImage: "leaf.fill")
                }
        }
        .environmentObject(soundLibrary)
        .environmentObject(audioManager)
        .environmentObject(sleepTimer)
        .task {
            await soundLibrary.loadIfNeeded()
        }
        .alert("该起床了", isPresented: $sleepTimer.showingAlarm) {
            Button("停止闹钟") {
                sleepTimer.stopAlarm()
            }
        }
    }
}
