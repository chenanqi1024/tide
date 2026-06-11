//
//  MeditateView.swift
//  tide
//
//  Created by Codex on 2026/6/4.
//

import SwiftUI

struct MeditateView: View {
    var body: some View {
        NavigationStack {
            List(AppData.meditations) { session in
                NavigationLink {
                    MeditationDetailView(session: session)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.title)
                            .font(.headline)
                        Text(session.intro)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("冥想")
        }
    }
}

struct MeditationDetailView: View {
    let session: MeditationSession

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(session.title)
                .font(.largeTitle.weight(.bold))
            Text(session.intro)
                .font(.title3)
                .foregroundStyle(.secondary)

            NavigationLink {
                MeditationGuideView(session: session)
            } label: {
                Label("开始", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 12)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MeditationGuideView: View {
    @Environment(\.dismiss) private var dismiss
    let session: MeditationSession

    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 28) {
            Text(session.title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(session.paragraphs[currentIndex])
                .font(.title2)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, minHeight: 180)

            Text("\(currentIndex + 1) / \(session.paragraphs.count)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    currentIndex = max(0, currentIndex - 1)
                } label: {
                    Label("上一段", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(currentIndex == 0)

                Button {
                    currentIndex = min(session.paragraphs.count - 1, currentIndex + 1)
                } label: {
                    Label("下一段", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentIndex == session.paragraphs.count - 1)
            }

            Button {
                dismiss()
            } label: {
                Label("结束", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(20)
        .navigationTitle("引导")
        .navigationBarTitleDisplayMode(.inline)
    }
}
