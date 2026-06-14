//
//  RadarViewController.swift
//  weatherlr
//
//  Created by drvolks on 2016-05-16.
//  Copyright © 2016 drvolks. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

private final class RadarImageOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    var image: UIImage

    init(image: UIImage, mapRect: MKMapRect) {
        self.image = image
        self.boundingMapRect = mapRect
        let center = MKMapPoint(x: mapRect.midX, y: mapRect.midY)
        self.coordinate = center.coordinate
        super.init()
    }
}

private final class RadarImageOverlayRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? RadarImageOverlay else { return }
        let rect = self.rect(for: overlay.boundingMapRect)
        UIGraphicsPushContext(context)
        overlay.image.draw(in: rect)
        UIGraphicsPopContext()
    }
}

private struct RadarViewport: Equatable, Sendable {
    private static let originShift = 20037508.342789244
    let mapX: Double
    let mapY: Double
    let mapWidth: Double
    let mapHeight: Double
    let pixelWidth: Int
    let pixelHeight: Int

    var mapRect: MKMapRect {
        MKMapRect(x: mapX, y: mapY, width: mapWidth, height: mapHeight)
    }

    func matches(_ mapRect: MKMapRect) -> Bool {
        mapX == mapRect.origin.x &&
        mapY == mapRect.origin.y &&
        mapWidth == mapRect.size.width &&
        mapHeight == mapRect.size.height
    }

    var bbox: (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        let rect = mapRect
        let minX = Self.mapXToMeters(rect.minX)
        let maxX = Self.mapXToMeters(rect.maxX)
        let maxY = Self.mapYToMeters(rect.minY)
        let minY = Self.mapYToMeters(rect.maxY)
        return (minX, minY, maxX, maxY)
    }

    private static func mapXToMeters(_ x: Double) -> Double {
        x / MKMapSize.world.width * (2 * originShift) - originShift
    }

    private static func mapYToMeters(_ y: Double) -> Double {
        originShift - y / MKMapSize.world.height * (2 * originShift)
    }
}

private struct RadarFrameData: Sendable {
    let index: Int
    let timeStep: String
    let data: Data
}

private struct RadarRenderedFrame {
    let index: Int
    let timeStep: String
    let image: UIImage
    let viewport: RadarViewport
}

class RadarViewController: UIViewController, MKMapViewDelegate {
    private enum Constants {
        static let maxImageDimension = 1536
        static let maxConcurrentFrameRequests = 3
        static let animationInterval: TimeInterval = 0.5
        static let regionReloadDelay: TimeInterval = 0.25
    }

    var city: City?
    private var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    private var didCenterOnUser = false

    private var timeSteps: [String] = []
    private var currentFrameIndex = 0
    private var renderedFrames: [Int: RadarRenderedFrame] = [:]
    private var playbackFrameIndices: [Int] = []
    private var activeViewport: RadarViewport?
    private var radarLoadTask: Task<Void, Never>?
    private var radarLoadGeneration = 0
    private var isLoadingRadarFrames = false
    private var regionReloadWorkItem: DispatchWorkItem?

    private var radarOverlay: RadarImageOverlay?
    private var radarOverlayRenderer: RadarImageOverlayRenderer?

    private var animationTimer: Timer?
    private var isPlaying = false
    private var sliderDebounceWorkItem: DispatchWorkItem?

    private var dismissButton: UIButton!
    private var playPauseButton: UIButton!
    private var timeSlider: UISlider!
    private var timeLabel: UILabel!
    private var controlBar: UIView!

    deinit {
        radarLoadTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Radar".localized()
        navigationController?.setNavigationBarHidden(true, animated: false)

        mapView = MKMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.mapType = .mutedStandard
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true
        mapView.delegate = self
        view.addSubview(mapView)

        if let city = city,
           let lat = Double(city.latitude),
           let lon = Double(city.longitude) {
            let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = MKCoordinateRegion(center: center, latitudinalMeters: 200_000, longitudinalMeters: 200_000)
            mapView.setRegion(region, animated: false)
        }

        if city == nil {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }

        setupDismissButton()
        setupControlBar()
        fetchTimeSteps()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadRadarForCurrentViewportIfNeeded(reason: "layout")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
        regionReloadWorkItem?.cancel()
        radarLoadTask?.cancel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        renderedFrames.removeAll()
        playbackFrameIndices.removeAll()
    }

    // MARK: - Dismiss Button

    private func setupDismissButton() {
        dismissButton = UIButton(type: .system)
        dismissButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        dismissButton.tintColor = UIColor.white.withAlphaComponent(0.8)
        let config = UIImage.SymbolConfiguration(pointSize: 36)
        dismissButton.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dismissButton.widthAnchor.constraint(equalToConstant: 44),
            dismissButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    // MARK: - Control Bar

    private func setupControlBar() {
        controlBar = UIView()
        controlBar.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        controlBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlBar)

        playPauseButton = UIButton(type: .system)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.isEnabled = false
        controlBar.addSubview(playPauseButton)

        timeSlider = UISlider()
        timeSlider.minimumValue = 0
        timeSlider.maximumValue = 0
        timeSlider.value = 0
        timeSlider.tintColor = .white
        timeSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        timeSlider.isEnabled = false
        controlBar.addSubview(timeSlider)

        timeLabel = UILabel()
        timeLabel.text = "--:--"
        timeLabel.textColor = .white
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        timeLabel.textAlignment = .right
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        controlBar.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            controlBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlBar.heightAnchor.constraint(equalToConstant: 60),

            playPauseButton.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor, constant: 16),
            playPauseButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 44),
            playPauseButton.heightAnchor.constraint(equalToConstant: 44),

            timeLabel.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor, constant: -16),
            timeLabel.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
            timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            timeSlider.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 12),
            timeSlider.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -12),
            timeSlider.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
        ])
    }

    // MARK: - Time Steps

    private func fetchTimeSteps() {
        print("[Radar] fetchTimeSteps called")
        if let cached = RadarTimeStepCache.shared.getCachedSteps() {
            print("[Radar] using cached steps")
            applyTimeSteps(cached)
            return
        }

        print("[Radar] cache miss - fetching time steps")
        let startTime = Date()
        guard let url = URL(string: "https://geo.weather.gc.ca/geomet?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities&LAYERS=RADAR_1KM_RRAI") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            let elapsed = Date().timeIntervalSince(startTime)
            guard let self = self, let data = data, error == nil else {
                print("[Radar] time step fetch failed in \(String(format: "%.1f", elapsed))s - \(error?.localizedDescription ?? "no data")")
                return
            }

            let steps = TimeDimensionParser(data: data).parse()
            print("[Radar] time step fetch complete - \(steps.count) steps in \(String(format: "%.1f", elapsed))s")

            DispatchQueue.main.async {
                self.applyTimeSteps(steps)
            }
        }.resume()
    }

    private func applyTimeSteps(_ steps: [String]) {
        guard !steps.isEmpty else { return }

        radarLoadTask?.cancel()
        stopAnimation()
        removeRadarOverlay()
        renderedFrames.removeAll()
        playbackFrameIndices.removeAll()
        activeViewport = nil
        isLoadingRadarFrames = false

        timeSteps = steps
        currentFrameIndex = steps.count - 1
        timeSlider.maximumValue = Float(steps.count - 1)
        timeSlider.value = Float(currentFrameIndex)
        timeSlider.isEnabled = true
        playPauseButton.isEnabled = false
        updateTimeLabel()

        loadRadarForCurrentViewportIfNeeded(reason: "time steps applied")
    }

    // MARK: - Image Loading

    private func loadRadarForCurrentViewportIfNeeded(reason: String) {
        guard !timeSteps.isEmpty,
              mapView.bounds.width > 0,
              mapView.bounds.height > 0,
              let viewport = currentViewport() else {
            return
        }

        if activeViewport == viewport, isLoadingRadarFrames || !renderedFrames.isEmpty {
            return
        }

        loadRadarFrames(for: viewport, startIndex: currentFrameIndex, reason: reason)
    }

    private func loadRadarFrames(for viewport: RadarViewport, startIndex: Int, reason: String) {
        radarLoadTask?.cancel()
        radarLoadGeneration += 1
        let generation = radarLoadGeneration

        activeViewport = viewport
        isLoadingRadarFrames = true
        renderedFrames.removeAll()
        playbackFrameIndices.removeAll()
        playPauseButton.isEnabled = false

        let steps = timeSteps
        print("[Radar] image load starting - \(steps.count) frames, \(viewport.pixelWidth)x\(viewport.pixelHeight), reason=\(reason)")

        radarLoadTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.loadCurrentFrameFirst(steps: steps, viewport: viewport, startIndex: startIndex, generation: generation)
        }
    }

    @MainActor
    private func loadCurrentFrameFirst(steps: [String], viewport: RadarViewport, startIndex: Int, generation: Int) async {
        guard steps.indices.contains(startIndex) else { return }
        let startTime = Date()

        if let frame = await renderedFrame(index: startIndex, timeStep: steps[startIndex], viewport: viewport) {
            guard isCurrentLoad(generation: generation, viewport: viewport) else { return }
            renderedFrames[startIndex] = frame
            rebuildPlaybackFrameIndices()
            displayFrame(at: startIndex)
            print("[Radar] current image loaded - frame=\(startIndex) in \(String(format: "%.1f", Date().timeIntervalSince(startTime)))s")
        } else {
            guard isCurrentLoad(generation: generation, viewport: viewport) else { return }
            print("[Radar] current image failed - frame=\(startIndex)")
        }

        await preloadRemainingFrames(steps: steps, viewport: viewport, referenceIndex: startIndex, generation: generation)
        if isCurrentLoad(generation: generation, viewport: viewport) {
            isLoadingRadarFrames = false
        }
    }

    @MainActor
    private func preloadRemainingFrames(steps: [String], viewport: RadarViewport, referenceIndex: Int, generation: Int) async {
        let remaining = steps.indices
            .filter { $0 != referenceIndex }
            .sorted { abs($0 - referenceIndex) < abs($1 - referenceIndex) }

        guard !remaining.isEmpty else {
            playPauseButton.isEnabled = playbackFrameIndices.count > 1
            return
        }

        let startTime = Date()
        var completed = 0
        var valid = 0
        var failed = 0

        await withTaskGroup(of: RadarFrameData?.self) { group in
            var next = 0
            let initialCount = min(Constants.maxConcurrentFrameRequests, remaining.count)

            for _ in 0..<initialCount {
                let index = remaining[next]
                let timeStep = steps[index]
                next += 1
                group.addTask {
                    await Self.fetchFrameData(index: index, timeStep: timeStep, viewport: viewport)
                }
            }

            while let result = await group.next() {
                guard isCurrentLoad(generation: generation, viewport: viewport) else {
                    group.cancelAll()
                    return
                }

                completed += 1
                if let result, let image = UIImage(data: result.data) {
                    renderedFrames[result.index] = RadarRenderedFrame(index: result.index,
                                                                      timeStep: result.timeStep,
                                                                      image: image,
                                                                      viewport: viewport)
                    valid += 1
                } else {
                    failed += 1
                }

                if next < remaining.count {
                    let index = remaining[next]
                    let timeStep = steps[index]
                    next += 1
                    group.addTask {
                        await Self.fetchFrameData(index: index, timeStep: timeStep, viewport: viewport)
                    }
                }
            }
        }

        guard isCurrentLoad(generation: generation, viewport: viewport) else { return }
        rebuildPlaybackFrameIndices()
        playPauseButton.isEnabled = playbackFrameIndices.count > 1
        print("[Radar] image preload complete - \(valid)/\(completed) remaining frames valid, failed=\(failed), playbackFrames=\(playbackFrameIndices.count), elapsed=\(String(format: "%.1f", Date().timeIntervalSince(startTime)))s")
    }

    @MainActor
    private func renderedFrame(index: Int, timeStep: String, viewport: RadarViewport) async -> RadarRenderedFrame? {
        guard let frameData = await Self.fetchFrameData(index: index, timeStep: timeStep, viewport: viewport),
              let image = UIImage(data: frameData.data) else {
            return nil
        }
        return RadarRenderedFrame(index: frameData.index, timeStep: frameData.timeStep, image: image, viewport: viewport)
    }

    private static func fetchFrameData(index: Int, timeStep: String, viewport: RadarViewport) async -> RadarFrameData? {
        guard !Task.isCancelled, let url = radarImageURL(timeStep: timeStep, viewport: viewport) else { return nil }
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)

        if let cached = URLCache.radarTileCache.cachedResponse(for: request),
           let validData = WMSTileOverlay.validate(cached.data, cached.response) {
            return RadarFrameData(index: index, timeStep: timeStep, data: validData)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let validData = WMSTileOverlay.validate(data, response) else {
                URLCache.radarTileCache.removeCachedResponse(for: request)
                WMSTileOverlay.logRejectedTile(data: data, response: response, error: nil)
                return nil
            }

            URLCache.radarTileCache.storeCachedResponse(CachedURLResponse(response: response, data: validData), for: request)
            return RadarFrameData(index: index, timeStep: timeStep, data: validData)
        } catch {
            guard !Task.isCancelled else { return nil }
            print("[Radar] image request failed - frame=\(index) error=\(error.localizedDescription)")
            return nil
        }
    }

    private static func radarImageURL(timeStep: String, viewport: RadarViewport) -> URL? {
        let bbox = viewport.bbox
        var components = URLComponents(string: "https://geo.weather.gc.ca/geomet")
        components?.queryItems = [
            URLQueryItem(name: "SERVICE", value: "WMS"),
            URLQueryItem(name: "VERSION", value: "1.3.0"),
            URLQueryItem(name: "REQUEST", value: "GetMap"),
            URLQueryItem(name: "LAYERS", value: "RADAR_1KM_RRAI"),
            URLQueryItem(name: "CRS", value: "EPSG:3857"),
            URLQueryItem(name: "BBOX", value: "\(bbox.minX),\(bbox.minY),\(bbox.maxX),\(bbox.maxY)"),
            URLQueryItem(name: "WIDTH", value: "\(viewport.pixelWidth)"),
            URLQueryItem(name: "HEIGHT", value: "\(viewport.pixelHeight)"),
            URLQueryItem(name: "FORMAT", value: "image/png"),
            URLQueryItem(name: "TRANSPARENT", value: "TRUE"),
            URLQueryItem(name: "TIME", value: timeStep),
        ]
        return components?.url
    }

    private func currentViewport() -> RadarViewport? {
        let mapRect = mapView.visibleMapRect
        guard mapRect.size.width > 0,
              mapRect.size.height > 0,
              mapRect.origin.x.isFinite,
              mapRect.origin.y.isFinite else {
            return nil
        }

        let bounds = mapView.bounds
        let scale = min(UIScreen.main.scale, 2.0)
        var pixelWidth = max(256, Int((bounds.width * scale).rounded(.up)))
        var pixelHeight = max(256, Int((bounds.height * scale).rounded(.up)))

        let maxDimension = max(pixelWidth, pixelHeight)
        if maxDimension > Constants.maxImageDimension {
            let ratio = Double(Constants.maxImageDimension) / Double(maxDimension)
            pixelWidth = max(256, Int((Double(pixelWidth) * ratio).rounded(.up)))
            pixelHeight = max(256, Int((Double(pixelHeight) * ratio).rounded(.up)))
        }

        return RadarViewport(mapX: mapRect.origin.x,
                             mapY: mapRect.origin.y,
                             mapWidth: mapRect.size.width,
                             mapHeight: mapRect.size.height,
                             pixelWidth: pixelWidth,
                             pixelHeight: pixelHeight)
    }

    private func isCurrentLoad(generation: Int, viewport: RadarViewport) -> Bool {
        !Task.isCancelled && generation == radarLoadGeneration && activeViewport == viewport
    }

    // MARK: - Display

    private func displayFrame(at index: Int) {
        guard let frame = renderedFrames[index] else { return }

        currentFrameIndex = index
        timeSlider.value = Float(index)
        updateTimeLabel()

        if let overlay = radarOverlay, frame.viewport.matches(overlay.boundingMapRect) {
            overlay.image = frame.image
            radarOverlayRenderer?.setNeedsDisplay()
        } else {
            replaceRadarOverlay(with: frame)
        }
    }

    private func replaceRadarOverlay(with frame: RadarRenderedFrame) {
        removeRadarOverlay()
        let overlay = RadarImageOverlay(image: frame.image, mapRect: frame.viewport.mapRect)
        radarOverlay = overlay
        mapView.addOverlay(overlay, level: .aboveRoads)
    }

    private func removeRadarOverlay() {
        if let overlay = radarOverlay {
            mapView.removeOverlay(overlay)
        }
        radarOverlay = nil
        radarOverlayRenderer = nil
    }

    private func rebuildPlaybackFrameIndices() {
        let viewport = activeViewport
        playbackFrameIndices = renderedFrames
            .filter { _, frame in frame.viewport == viewport }
            .map(\.key)
            .sorted()
    }

    private func updateTimeLabel() {
        guard timeSteps.indices.contains(currentFrameIndex) else { return }
        let isoString = timeSteps[currentFrameIndex]

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        guard let date = isoFormatter.date(from: isoString) else {
            timeLabel.text = "--:--"
            return
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        displayFormatter.timeZone = TimeZone.current
        let timeString = displayFormatter.string(from: date)

        let tzFormatter = DateFormatter()
        tzFormatter.dateFormat = "zzz"
        tzFormatter.timeZone = TimeZone.current
        let tzString = tzFormatter.string(from: date)

        timeLabel.text = "\(timeString) \(tzString)"
    }

    // MARK: - Animation

    @objc private func playPauseTapped() {
        if isPlaying {
            stopAnimation()
        } else {
            startAnimation()
        }
    }

    private func startAnimation() {
        guard animationTimer == nil, playbackFrameIndices.count > 1 else { return }

        isPlaying = true
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        animationTimer = Timer.scheduledTimer(withTimeInterval: Constants.animationInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.advanceAnimationFrame()
            }
        }
    }

    private func stopAnimation() {
        isPlaying = false
        animationTimer?.invalidate()
        animationTimer = nil
        playPauseButton?.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }

    private func advanceAnimationFrame() {
        guard !playbackFrameIndices.isEmpty else {
            stopAnimation()
            return
        }

        let nextIndex: Int
        if let currentPlaybackPosition = playbackFrameIndices.firstIndex(of: currentFrameIndex) {
            let nextPlaybackPosition = playbackFrameIndices.index(after: currentPlaybackPosition)
            nextIndex = nextPlaybackPosition < playbackFrameIndices.endIndex ? playbackFrameIndices[nextPlaybackPosition] : playbackFrameIndices[0]
        } else {
            nextIndex = playbackFrameIndices[0]
        }

        displayFrame(at: nextIndex)
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        if isPlaying {
            stopAnimation()
        }

        let requestedIndex = Int(sender.value.rounded())
        currentFrameIndex = requestedIndex
        updateTimeLabel()

        sliderDebounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.displayOrLoadFrame(at: requestedIndex)
        }
        sliderDebounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
    }

    private func displayOrLoadFrame(at index: Int) {
        if renderedFrames[index] != nil {
            displayFrame(at: index)
            return
        }

        guard timeSteps.indices.contains(index),
              let viewport = activeViewport ?? currentViewport() else {
            return
        }

        let generation = radarLoadGeneration
        let timeStep = timeSteps[index]
        Task { @MainActor [weak self] in
            guard let self = self,
                  let frame = await self.renderedFrame(index: index, timeStep: timeStep, viewport: viewport),
                  self.isCurrentLoad(generation: generation, viewport: viewport) else {
                return
            }
            self.renderedFrames[index] = frame
            self.rebuildPlaybackFrameIndices()
            self.displayFrame(at: index)
        }
    }

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if isPlaying {
            stopAnimation()
        }
        regionReloadWorkItem?.cancel()
        radarLoadTask?.cancel()
        radarLoadGeneration += 1
        isLoadingRadarFrames = false
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regionReloadWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.loadRadarFramesForSettledRegion()
        }
        regionReloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.regionReloadDelay, execute: work)
    }

    private func loadRadarFramesForSettledRegion() {
        loadRadarForCurrentViewportIfNeeded(reason: "region settled")
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? RadarImageOverlay {
            let renderer = RadarImageOverlayRenderer(overlay: overlay)
            radarOverlayRenderer = renderer
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}

// MARK: - CLLocationManagerDelegate

extension RadarViewController: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !didCenterOnUser, let location = locations.last else { return }
        didCenterOnUser = true
        locationManager.stopUpdatingLocation()

        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 200_000, longitudinalMeters: 200_000)
        mapView.setRegion(region, animated: true)
    }
}
