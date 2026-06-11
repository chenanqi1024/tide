//
//  RemoteImageView.swift
//  tide
//
//  Created by Codex on 2026/6/4.
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class RemoteImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var didFail = false

    private var currentURLString: String?

    func load(_ urlString: String?) async {
        guard currentURLString != urlString else { return }
        currentURLString = urlString
        image = nil
        didFail = false

        guard let urlString, !urlString.isEmpty, let url = URL(string: urlString) else {
            return
        }

        do {
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            request.timeoutInterval = 20
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.setValue("no-cache", forHTTPHeaderField: "Pragma")

            let configuration = URLSessionConfiguration.ephemeral
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            configuration.urlCache = nil

            let session = URLSession(configuration: configuration)
            defer { session.finishTasksAndInvalidate() }

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode,
                  let loadedImage = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }

            image = loadedImage
        } catch {
            didFail = true
        }
    }
}

struct CoverImageView: View {
    let urlString: String?
    let title: String

    @StateObject private var loader = RemoteImageLoader()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image = loader.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .task(id: urlString) {
            await loader.load(urlString)
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.teal.opacity(0.75), Color.indigo.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "waveform")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .accessibilityHidden(true)
        }
        .accessibilityLabel(title)
    }
}

struct LoadingRetryView: View {
    let isLoading: Bool
    let message: String?
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView("加载中...")
                    .font(.headline)
            } else {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(message ?? "加载失败")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Button("重试", action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SoundCardView: View {
    let sound: SoundItem

    var body: some View {
        ZStack {
            CoverImageView(urlString: sound.cover, title: sound.name)

            LinearGradient(
                colors: [.black.opacity(0.45), .black.opacity(0.15), .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(sound.name)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .padding(12)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
