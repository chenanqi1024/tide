//
//  SoundLibrary.swift
//  tide
//
//  Created by Codex on 2026/6/4.
//

import Combine
import Foundation

@MainActor
final class SoundLibrary: ObservableObject {
    @Published private(set) var sounds: [SoundItem] = []
    @Published private(set) var alarm: SoundItem?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let apiURL = URL(string: "https://zzz-pet.oss-cn-hangzhou.aliyuncs.com/api/sounds.json")!

    func loadIfNeeded() async {
        guard sounds.isEmpty, !isLoading else { return }
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            var request = URLRequest(url: apiURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
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
                  200..<300 ~= httpResponse.statusCode else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(SoundsResponse.self, from: data)
            alarm = decoded.alarm
            sounds = decoded.sounds
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "声音加载失败，请检查网络后重试。"
        }
    }
}
