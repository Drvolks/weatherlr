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

private final class RadarTilePrefetchStats: @unchecked Sendable {
    private let lock = NSLock()
    private var downloadedTiles = 0
    private var rejectedTiles = 0

    func recordDownloaded() {
        lock.lock()
        downloadedTiles += 1
        lock.unlock()
    }

    func recordRejected() {
        lock.lock()
        rejectedTiles += 1
        lock.unlock()
    }

    func snapshot() -> (downloaded: Int, rejected: Int) {
        lock.lock()
        defer { lock.unlock() }
        return (downloadedTiles, rejectedTiles)
    }
}

class RadarViewController: UIViewController, MKMapViewDelegate {
    private enum Constants {
        static let visibleTilePrefetchPadding = 1
        static let maxConcurrentTileRequestsPerFrame = 4
    }

    var city: City?
    private var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    private var didCenterOnUser = false

    private var timeSteps: [String] = []
    private var currentFrameIndex = 0
    private var animationTimer: Timer?
    private var isPlaying = false
    private var sliderDebounceWorkItem: DispatchWorkItem?
    private var isInitialPrefetchPending = false
    private var didStartInitialPrefetch = false
    private var isPreparingPlaybackFrames = false
    private var didPreparePlaybackFrames = false

    // Stacked overlays: one per time step, toggled via renderer alpha
    private var tileOverlays: [WMSTileOverlay] = []
    private var rendererMap: [ObjectIdentifier: MKTileOverlayRenderer] = [:]
    private var overlaysAddedToMap: Set<Int> = []

    // Dedicated session for background prefetch
    private lazy var prefetchSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 6
        config.urlCache = .radarTileCache
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    private var dismissButton: UIButton!
    private var playPauseButton: UIButton!
    private var timeSlider: UISlider!
    private var timeLabel: UILabel!
    private var controlBar: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Radar".localized()

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startInitialPrefetchIfReady()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Keep disk-backed URLCache intact; clear only in-memory tile cache.
        TileDataCache.shared.clear()
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
        dismiss(animated: true, completion: nil)
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
            print("[Radar] using cached steps — applying immediately")
            applyTimeSteps(cached)
            return
        }

        print("[Radar] cache miss — fetching from network...")
        let startTime = Date()
        let urlString = "https://geo.weather.gc.ca/geomet?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities&LAYERS=RADAR_1KM_RRAI"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            let elapsed = Date().timeIntervalSince(startTime)
            guard let self = self, let data = data, error == nil else {
                print("[Radar] network fetch failed after \(String(format: "%.1f", elapsed))s — \(error?.localizedDescription ?? "no data")")
                return
            }

            let parser = TimeDimensionParser(data: data)
            let steps = parser.parse()
            print("[Radar] network fetch complete — \(steps.count) steps in \(String(format: "%.1f", elapsed))s")

            DispatchQueue.main.async {
                self.applyTimeSteps(steps)
            }
        }.resume()
    }

    private func applyTimeSteps(_ steps: [String]) {
        guard !steps.isEmpty else { return }

        // Clean up any existing overlays
        for overlay in tileOverlays {
            mapView.removeOverlay(overlay)
        }
        tileOverlays.removeAll()
        rendererMap.removeAll()
        overlaysAddedToMap.removeAll()

        timeSteps = steps
        currentFrameIndex = steps.count - 1
        isPreparingPlaybackFrames = false
        didPreparePlaybackFrames = false

        // Create one overlay per time step
        for step in steps {
            let overlay = WMSTileOverlay(time: step)
            overlay.tileSize = CGSize(width: 256, height: 256)
            tileOverlays.append(overlay)
        }

        timeSlider.maximumValue = Float(steps.count - 1)
        timeSlider.value = Float(currentFrameIndex)
        timeSlider.isEnabled = true
        updateTimeLabel()

        // Defer visibleTilePaths() until after the map has laid out, then add
        // the first overlay only after its visible tiles have been prefetched.
        // That prevents MapKit from drawing a half-populated first frame.
        isInitialPrefetchPending = true
        didStartInitialPrefetch = false
        startInitialPrefetchIfReady()
    }

    private func addOverlayToMap(at index: Int) {
        guard index >= 0, index < tileOverlays.count, !overlaysAddedToMap.contains(index) else { return }
        overlaysAddedToMap.insert(index)
        mapView.addOverlay(tileOverlays[index], level: .aboveRoads)
    }

    private func addRemainingOverlays() {
        for index in 0..<tileOverlays.count {
            addOverlayToMap(at: index)
        }
    }

    // MARK: - Tile Prefetching

    private struct TilePrefetchResult {
        let totalTiles: Int
        let cachedTiles: Int
        let downloadedTiles: Int
        let rejectedTiles: Int

        var validTiles: Int {
            cachedTiles + downloadedTiles
        }
    }

    private struct TilePrefetchSummary {
        var frameCount = 0
        var totalTiles = 0
        var cachedTiles = 0
        var downloadedTiles = 0
        var rejectedTiles = 0

        var validTiles: Int {
            cachedTiles + downloadedTiles
        }

        mutating func add(_ result: TilePrefetchResult) {
            frameCount += 1
            totalTiles += result.totalTiles
            cachedTiles += result.cachedTiles
            downloadedTiles += result.downloadedTiles
            rejectedTiles += result.rejectedTiles
        }
    }

    private final class TilePrefetchCompletion: @unchecked Sendable {
        private let completion: (TilePrefetchResult) -> Void

        init(_ completion: @escaping (TilePrefetchResult) -> Void) {
            self.completion = completion
        }

        func callAsFunction(_ result: TilePrefetchResult) {
            completion(result)
        }
    }

    private func startInitialPrefetchIfReady() {
        guard isInitialPrefetchPending,
              !didStartInitialPrefetch,
              !timeSteps.isEmpty,
              mapView.bounds.width > 0,
              mapView.bounds.height > 0 else {
            return
        }

        let tilePaths = visibleTilePaths()
        guard !tilePaths.isEmpty else { return }

        isInitialPrefetchPending = false
        didStartInitialPrefetch = true
        playPauseButton.isEnabled = false

        let initialFrameIndex = currentFrameIndex
        let zoomLevel = tilePaths.first?.z ?? -1
        let currentFrameStartTime = Date()
        print("[Radar] initial prefetch starting - \(tilePaths.count) visible tiles at z=\(zoomLevel)")

        prefetchTilesForFrame(initialFrameIndex, tilePaths: tilePaths, session: prefetchSession) { [weak self] result in
            guard let self = self else { return }

            var summary = TilePrefetchSummary()
            summary.add(result)
            self.logPrefetch(summary, elapsed: Date().timeIntervalSince(currentFrameStartTime), context: "current frame")

            self.addOverlayToMap(at: initialFrameIndex)
            self.applyCurrentFrame()

            if result.rejectedTiles > 0 {
                self.reloadCurrentFrameRenderer(reason: "current frame prefetch rejected \(result.rejectedTiles) tiles")
            }

            let remaining = Array(0..<self.timeSteps.count).filter { $0 != initialFrameIndex }
            self.prefetchFrames(remaining, tilePaths: tilePaths, referenceFrameIndex: initialFrameIndex)
        }

    }

    private func prefetchTilesForFrame(_ frameIndex: Int, tilePaths: [MKTileOverlayPath], session: URLSession, completion: @escaping (TilePrefetchResult) -> Void) {
        guard frameIndex < tileOverlays.count else {
            DispatchQueue.main.async {
                completion(TilePrefetchResult(totalTiles: 0, cachedTiles: 0, downloadedTiles: 0, rejectedTiles: 0))
            }
            return
        }

        let overlay = tileOverlays[frameIndex]
        var urls: [URL] = []
        var cachedTiles = 0
        for path in tilePaths {
            let url = overlay.url(forTilePath: path)
            if TileDataCache.shared.get(url) == nil {
                urls.append(url)
            } else {
                cachedTiles += 1
            }
        }

        guard !urls.isEmpty else {
            DispatchQueue.main.async {
                completion(TilePrefetchResult(totalTiles: tilePaths.count, cachedTiles: cachedTiles, downloadedTiles: 0, rejectedTiles: 0))
            }
            return
        }

        let group = DispatchGroup()
        let stats = RadarTilePrefetchStats()
        let pendingURLs = urls
        let alreadyCachedTiles = cachedTiles
        let totalTiles = tilePaths.count
        let completionHandler = TilePrefetchCompletion(completion)

        DispatchQueue.global(qos: .utility).async {
            let semaphore = DispatchSemaphore(value: Constants.maxConcurrentTileRequestsPerFrame)

            for url in pendingURLs {
                semaphore.wait()
                group.enter()
                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
                session.dataTask(with: request) { data, response, error in
                    if let validData = WMSTileOverlay.validate(data, response) {
                        TileDataCache.shared.set(validData, for: url)
                        if let response {
                            session.configuration.urlCache?.storeCachedResponse(CachedURLResponse(response: response, data: validData), for: request)
                        }
                        stats.recordDownloaded()
                    } else {
                        // Same guard as WMSTileOverlay.loadTile: never cache a non-PNG body,
                        // and evict any poisoned disk entry so the tile is re-fetched later.
                        session.configuration.urlCache?.removeCachedResponse(for: request)
                        WMSTileOverlay.logRejectedTile(data: data, response: response, error: error)
                        stats.recordRejected()
                    }
                    semaphore.signal()
                    group.leave()
                }.resume()
            }

            group.notify(queue: .main) {
                let (downloaded, rejected) = stats.snapshot()

                completionHandler(TilePrefetchResult(totalTiles: totalTiles,
                                                     cachedTiles: alreadyCachedTiles,
                                                     downloadedTiles: downloaded,
                                                     rejectedTiles: rejected))
            }
        }
    }

    /// Prefetches remaining frames with bounded concurrency and proximity priority.
    private func prefetchFrames(_ frameIndices: [Int], tilePaths: [MKTileOverlayPath], referenceFrameIndex: Int) {
        guard !frameIndices.isEmpty else {
            preparePlaybackFramesForAnimation(reason: "single-frame prefetch complete") { [weak self] in
                self?.playPauseButton.isEnabled = true
            }
            return
        }

        let startTime = Date()
        let sorted = frameIndices.sorted { abs($0 - referenceFrameIndex) < abs($1 - referenceFrameIndex) }
        let totalFrames = sorted.count
        var completedCount = 0
        var nextIndex = 0
        var inFlight = 0
        let maxInFlight = 3
        var summary = TilePrefetchSummary()

        print("[Radar] bounded prefetch starting - \(totalFrames) frames, maxInFlight=\(maxInFlight)")

        func launchMoreIfNeeded() {
            while inFlight < maxInFlight, nextIndex < sorted.count {
                let frameIndex = sorted[nextIndex]
                nextIndex += 1
                inFlight += 1

                prefetchTilesForFrame(frameIndex, tilePaths: tilePaths, session: prefetchSession) { [weak self] result in
                    guard let self = self else { return }
                    inFlight -= 1
                    completedCount += 1
                    summary.add(result)

                    if completedCount == totalFrames {
                        let elapsed = Date().timeIntervalSince(startTime)
                        self.logPrefetch(summary, elapsed: elapsed, context: "remaining frames")
                        self.preparePlaybackFramesForAnimation(reason: "prefetch complete") {
                            self.playPauseButton.isEnabled = true
                        }
                        return
                    }

                    launchMoreIfNeeded()
                }
            }
        }

        launchMoreIfNeeded()
    }

    private func logPrefetch(_ summary: TilePrefetchSummary, elapsed: TimeInterval, context: String) {
        let frameWord = summary.frameCount == 1 ? "frame" : "frames"
        let elapsedText = elapsed > 0 ? " in \(String(format: "%.1f", elapsed))s" : ""
        print("[Radar] prefetch: \(summary.validTiles)/\(summary.totalTiles) valid tiles across \(summary.frameCount) \(frameWord)\(elapsedText) (\(context), cached=\(summary.cachedTiles), downloaded=\(summary.downloadedTiles), rejected=\(summary.rejectedTiles))")
    }

    private func preparePlaybackFramesForAnimation(reason: String, completion: @escaping () -> Void) {
        guard !tileOverlays.isEmpty else {
            completion()
            return
        }

        if didPreparePlaybackFrames {
            completion()
            return
        }

        guard !isPreparingPlaybackFrames else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.preparePlaybackFramesForAnimation(reason: reason, completion: completion)
            }
            return
        }

        isPreparingPlaybackFrames = true
        addRemainingOverlays()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setPlaybackRendererAlphas()
            self.didPreparePlaybackFrames = true
            self.isPreparingPlaybackFrames = false
            print("[Radar] playback ready - \(self.overlaysAddedToMap.count)/\(self.tileOverlays.count) overlays prepared (\(reason))")
            completion()
        }
    }

    private func setPlaybackRendererAlphas() {
        for (index, overlay) in tileOverlays.enumerated() {
            renderer(for: overlay)?.alpha = (index == currentFrameIndex) ? 1.0 : 0.0
        }
    }

    private func renderer(for overlay: WMSTileOverlay) -> MKTileOverlayRenderer? {
        let id = ObjectIdentifier(overlay)
        if let renderer = rendererMap[id] {
            return renderer
        }
        if let renderer = mapView.renderer(for: overlay) as? MKTileOverlayRenderer {
            rendererMap[id] = renderer
            return renderer
        }
        return nil
    }

    private func visibleTilePaths() -> [MKTileOverlayPath] {
        let mapRect = mapView.visibleMapRect
        guard mapRect.size.width > 0, mapRect.size.height > 0 else { return [] }

        let zoomScale = Double(mapView.bounds.width) / mapRect.size.width
        guard zoomScale.isFinite, zoomScale > 0 else { return [] }

        let zoomLevel = max(0, Int(log2(zoomScale * MKMapSize.world.width / 256.0)))

        let tileCount = Double(1 << zoomLevel)
        let maxTileIndex = Int(tileCount) - 1
        let rawMinX = Int((mapRect.origin.x / MKMapSize.world.width * tileCount).rounded(.down))
        let rawMaxX = Int(((mapRect.origin.x + mapRect.size.width) / MKMapSize.world.width * tileCount).rounded(.down))
        let rawMinY = Int((mapRect.origin.y / MKMapSize.world.height * tileCount).rounded(.down))
        let rawMaxY = Int(((mapRect.origin.y + mapRect.size.height) / MKMapSize.world.height * tileCount).rounded(.down))

        let minX = max(0, rawMinX - Constants.visibleTilePrefetchPadding)
        let maxX = min(maxTileIndex, rawMaxX + Constants.visibleTilePrefetchPadding)
        let minY = max(0, rawMinY - Constants.visibleTilePrefetchPadding)
        let maxY = min(maxTileIndex, rawMaxY + Constants.visibleTilePrefetchPadding)

        guard minX <= maxX, minY <= maxY else { return [] }

        var paths: [MKTileOverlayPath] = []
        for x in minX...maxX {
            for y in minY...maxY {
                paths.append(MKTileOverlayPath(x: x, y: y, z: zoomLevel, contentScaleFactor: 1.0))
            }
        }
        return paths
    }

    private func updateTimeLabel() {
        guard currentFrameIndex < timeSteps.count else { return }
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

    private func applyCurrentFrame() {
        guard currentFrameIndex < tileOverlays.count else { return }

        if isPlaying {
            // During animation, toggle alpha for smooth transitions
            addOverlayToMap(at: currentFrameIndex)
            for (index, overlay) in tileOverlays.enumerated() {
                let id = ObjectIdentifier(overlay)
                rendererMap[id]?.alpha = (index == currentFrameIndex) ? 1.0 : 0.0
            }
        } else {
            // When not animating, only keep the current overlay on the map
            // so MapKit doesn't load tiles for all hidden frames
            for (index, overlay) in tileOverlays.enumerated() {
                if index != currentFrameIndex && overlaysAddedToMap.contains(index) {
                    mapView.removeOverlay(overlay)
                    overlaysAddedToMap.remove(index)
                    rendererMap.removeValue(forKey: ObjectIdentifier(overlay))
                    didPreparePlaybackFrames = false
                }
            }
            addOverlayToMap(at: currentFrameIndex)
            let id = ObjectIdentifier(tileOverlays[currentFrameIndex])
            rendererMap[id]?.alpha = 1.0
        }
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
        guard animationTimer == nil, !isPreparingPlaybackFrames else { return }

        guard didPreparePlaybackFrames else {
            playPauseButton.isEnabled = false
            preparePlaybackFramesForAnimation(reason: "manual playback start") { [weak self] in
                guard let self = self else { return }
                self.playPauseButton.isEnabled = true
                self.startAnimation()
            }
            return
        }

        addRemainingOverlays()
        setPlaybackRendererAlphas()
        isPlaying = true
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.timeSteps.isEmpty else { return }
                self.currentFrameIndex = (self.currentFrameIndex + 1) % self.timeSteps.count
                self.timeSlider.value = Float(self.currentFrameIndex)
                self.updateTimeLabel()
                self.applyCurrentFrame()
            }
        }
    }

    private func stopAnimation() {
        isPlaying = false
        animationTimer?.invalidate()
        animationTimer = nil
        playPauseButton?.setImage(UIImage(systemName: "play.fill"), for: .normal)
        applyCurrentFrame()
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        if isPlaying {
            stopAnimation()
        }
        currentFrameIndex = Int(sender.value)
        updateTimeLabel()

        sliderDebounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.applyCurrentFrame()
        }
        sliderDebounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
    }

    // MARK: - Overlay Recovery

    /// Forces the current frame's renderer to drop any partial state and
    /// re-request its visible tiles. A failed `loadTile` (e.g. a GeoMet 429)
    /// otherwise leaves a permanent hole because MapKit marks the slot drawn and
    /// never retries on its own.
    private func reloadCurrentFrameRenderer(reason: String) {
        guard currentFrameIndex >= 0, currentFrameIndex < tileOverlays.count else { return }
        let id = ObjectIdentifier(tileOverlays[currentFrameIndex])
        guard let renderer = rendererMap[id] else { return }
        print("[Radar] \(reason) — reloading current frame renderer")
        renderer.reloadData()
    }

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // After the map settles (initial setRegion, didUpdateLocations, or a user
        // gesture), re-request visible tiles so partial overlays fill in.
        reloadCurrentFrameRenderer(reason: "region settled")
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tileOverlay = overlay as? WMSTileOverlay {
            let renderer = MKTileOverlayRenderer(overlay: tileOverlay)
            let id = ObjectIdentifier(tileOverlay)
            rendererMap[id] = renderer

            // Set initial alpha: visible only if this is the current frame
            if let index = tileOverlays.firstIndex(where: { $0 === tileOverlay }) {
                renderer.alpha = (index == currentFrameIndex) ? 1.0 : 0.0
            } else {
                renderer.alpha = 0.0
            }

            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
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
