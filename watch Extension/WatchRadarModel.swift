//
//  WatchRadarModel.swift
//  watch Extension
//
//  Created by drvolks on 2026-07-18.
//  Copyright © 2026 drvolks. All rights reserved.
//

import Foundation
import UIKit
import Observation

/// Drives the watch radar page: loads the CBMT basemap and the latest radar
/// frame when the page appears, and fetches the remaining animation frames
/// only when the user starts playback (network/battery frugality).
@Observable @MainActor
final class WatchRadarModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case unavailable
        case failed(String)
    }

    private enum Constants {
        static let maxFrames = 8
        static let viewportWidthMeters: Double = 240_000
        static let maxPixelDimension = 512
        static let pixelScale: CGFloat = 2
        static let maxConcurrentFrameRequests = 2
        static let animationInterval: Duration = .milliseconds(500)
        static let reloadInterval: TimeInterval = 300
    }

    private(set) var state: LoadState = .idle
    private(set) var basemap: UIImage?
    private(set) var timeSteps: [String] = []
    private(set) var currentIndex = 0
    private(set) var isPlaying = false

    private var framesByIndex: [Int: UIImage] = [:]
    private var viewport: RadarMercatorViewport?
    private var loadedCityId: String?
    private var loadedDate: Date?
    private var loadGeneration = 0
    private var loadTask: Task<Void, Never>?
    private var frameLoadTask: Task<Void, Never>?
    private var playbackTask: Task<Void, Never>?
    private var allFramesRequested = false

    var currentImage: UIImage? {
        framesByIndex[currentIndex] ?? framesByIndex[timeSteps.count - 1]
    }

    var currentTimeLabel: String {
        guard timeSteps.indices.contains(currentIndex) else { return "--:--" }
        return RadarImagery.localTimeLabel(isoTimeStep: timeSteps[currentIndex])
    }

    // MARK: - Loading

    func load(for city: City?, sizePoints: CGSize) {
        guard let city, !city.radarId.isEmpty,
              let latitude = Double(city.latitude),
              let longitude = Double(city.longitude) else {
            state = .unavailable
            return
        }

        if loadedCityId == city.id, state == .loaded,
           let loadedDate, Date().timeIntervalSince(loadedDate) < Constants.reloadInterval {
            return
        }

        let isNewCity = loadedCityId != city.id
        loadGeneration += 1
        let generation = loadGeneration
        stopPlayback()
        loadTask?.cancel()
        frameLoadTask?.cancel()
        framesByIndex = [:]
        allFramesRequested = false
        if isNewCity {
            basemap = nil
        }
        state = .loading

        let scale = Constants.pixelScale
        var pixelWidth = max(1, Int((sizePoints.width * scale).rounded(.up)))
        var pixelHeight = max(1, Int((sizePoints.height * scale).rounded(.up)))
        let maxDimension = max(pixelWidth, pixelHeight)
        if maxDimension > Constants.maxPixelDimension {
            let ratio = Double(Constants.maxPixelDimension) / Double(maxDimension)
            pixelWidth = max(1, Int((Double(pixelWidth) * ratio).rounded(.up)))
            pixelHeight = max(1, Int((Double(pixelHeight) * ratio).rounded(.up)))
        }

        guard let viewport = RadarMercatorViewport(centerLatitude: latitude,
                                                   centerLongitude: longitude,
                                                   widthMeters: Constants.viewportWidthMeters,
                                                   pixelWidth: pixelWidth,
                                                   pixelHeight: pixelHeight) else {
            state = .unavailable
            return
        }
        self.viewport = viewport
        loadedCityId = city.id

        loadTask = Task { [weak self] in
            let steps: [String]
            if let cached = RadarTimeStepCache.shared.getCachedSteps(), !cached.isEmpty {
                steps = cached
            } else {
                steps = await Self.fetchTimeSteps()
            }

            guard let self, !Task.isCancelled, generation == self.loadGeneration else { return }
            guard !steps.isEmpty else {
                self.state = .failed("Radar error".localized())
                return
            }

            self.timeSteps = Array(steps.suffix(Constants.maxFrames))
            self.currentIndex = self.timeSteps.count - 1

            let latestStep = self.timeSteps[self.currentIndex]
            let needsBasemap = self.basemap == nil
            async let basemapImage: UIImage? = needsBasemap
                ? Self.fetchImage(RadarImagery.basemapURL(viewport: viewport))
                : nil
            async let latestFrame: UIImage? = Self.fetchImage(
                RadarImagery.radarImageURL(timeStep: latestStep, viewport: viewport))

            let (fetchedBasemap, fetchedFrame) = await (basemapImage, latestFrame)
            guard !Task.isCancelled, generation == self.loadGeneration else { return }

            if let fetchedBasemap {
                self.basemap = fetchedBasemap
            }
            guard let fetchedFrame else {
                self.state = .failed("Radar error".localized())
                return
            }
            self.framesByIndex[self.currentIndex] = fetchedFrame
            self.loadedDate = Date()
            self.state = .loaded
        }
    }

    func retry(for city: City?, sizePoints: CGSize) {
        loadedCityId = nil
        load(for: city, sizePoints: sizePoints)
    }

    func cancel() {
        stopPlayback()
        loadTask?.cancel()
        frameLoadTask?.cancel()
        loadGeneration += 1
    }

    // MARK: - Playback

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard state == .loaded, timeSteps.count > 1 else { return }
        ensureAllFramesLoading()
        isPlaying = true
        playbackTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Constants.animationInterval)
                guard let self, !Task.isCancelled else { return }
                self.advanceFrame()
            }
        }
    }

    private func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
    }

    /// Digital Crown scrubbing: jump to a frame and pause the loop.
    func scrub(to index: Int) {
        guard state == .loaded, !timeSteps.isEmpty else { return }
        stopPlayback()
        ensureAllFramesLoading()
        currentIndex = min(max(index, 0), timeSteps.count - 1)
    }

    private func advanceFrame() {
        let loadedIndices = framesByIndex.keys.sorted()
        guard !loadedIndices.isEmpty else { return }
        if let next = loadedIndices.first(where: { $0 > currentIndex }) {
            currentIndex = next
        } else {
            currentIndex = loadedIndices[0]
        }
    }

    /// Fetches every animation frame that is not loaded yet, newest first,
    /// with limited concurrency. Called on first play / first scrub.
    private func ensureAllFramesLoading() {
        guard !allFramesRequested, let viewport else { return }
        allFramesRequested = true

        let generation = loadGeneration
        let missing = timeSteps.indices
            .filter { framesByIndex[$0] == nil }
            .sorted(by: >)
        guard !missing.isEmpty else { return }
        let steps = timeSteps

        frameLoadTask = Task { [weak self] in
            await withTaskGroup(of: (Int, UIImage?).self) { group in
                var pending = missing[...]
                var active = 0

                while active > 0 || !pending.isEmpty {
                    while active < Constants.maxConcurrentFrameRequests, let index = pending.popFirst() {
                        active += 1
                        group.addTask {
                            let url = RadarImagery.radarImageURL(timeStep: steps[index], viewport: viewport)
                            return (index, await Self.fetchImage(url))
                        }
                    }

                    guard let (index, image) = await group.next() else { return }
                    active -= 1
                    guard let self, !Task.isCancelled, generation == self.loadGeneration else {
                        group.cancelAll()
                        return
                    }
                    if let image {
                        self.framesByIndex[index] = image
                    }
                }
            }
        }
    }

    // MARK: - Fetching

    nonisolated private static func fetchTimeSteps() async -> [String] {
        let urlString = "https://geo.weather.gc.ca/geomet?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities&LAYERS=RADAR_1KM_RRAI"
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url) else {
            return []
        }
        return TimeDimensionParser(data: data).parse()
    }

    nonisolated private static func fetchImage(_ url: URL?) async -> UIImage? {
        guard let url else { return nil }
        let request = URLRequest(url: url, timeoutInterval: 30)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let validData = RadarImagery.validatePNG(data, response) else {
            return nil
        }
        return UIImage(data: validData)
    }
}
