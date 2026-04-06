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

class RadarViewController: UIViewController, MKMapViewDelegate {

    var city: City?
    private var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    private var didCenterOnUser = false

    private var timeSteps: [String] = []
    private var currentFrameIndex = 0
    private var animationTimer: Timer?
    private var isPlaying = false

    // Stacked overlays: one per time step, toggled via renderer alpha
    private var tileOverlays: [WMSTileOverlay] = []
    private var rendererMap: [ObjectIdentifier: MKTileOverlayRenderer] = [:]
    private var overlaysAddedToMap: Set<Int> = []

    // Dedicated session for background prefetch
    private lazy var prefetchSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 6
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
        mapView.mapType = .hybrid
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

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        setupDismissButton()
        setupControlBar()
        fetchTimeSteps()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        TileDataCache.shared.clear()
    }

    // MARK: - Dismiss Button

    private func setupDismissButton() {
        dismissButton = UIButton(type: .system)
        dismissButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        dismissButton.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 28)
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

        // Phase 1: prefetch current frame tiles, then show overlay
        let tilePaths = visibleTilePaths()
        prefetchTilesForFrame(currentFrameIndex, tilePaths: tilePaths, session: URLSession.shared) { [weak self] in
            guard let self = self else { return }

            // Current frame tiles are cached — add overlay (instant cache hits)
            self.addOverlayToMap(at: self.currentFrameIndex)
            self.applyCurrentFrame()

            // Phase 2: prefetch remaining frames in parallel
            let remaining = Array(0..<steps.count).filter { $0 != self.currentFrameIndex }
            self.prefetchFramesSequentially(remaining, tilePaths: tilePaths)
        }
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

    private func prefetchTilesForFrame(_ frameIndex: Int, tilePaths: [MKTileOverlayPath], session: URLSession, completion: @escaping () -> Void) {
        guard frameIndex < tileOverlays.count else {
            DispatchQueue.main.async { completion() }
            return
        }

        let overlay = tileOverlays[frameIndex]
        var urls: [URL] = []
        for path in tilePaths {
            let url = overlay.url(forTilePath: path)
            if TileDataCache.shared.get(url) == nil {
                urls.append(url)
            }
        }

        guard !urls.isEmpty else {
            DispatchQueue.main.async { completion() }
            return
        }

        let group = DispatchGroup()
        for url in urls {
            group.enter()
            session.dataTask(with: url) { data, _, _ in
                if let data = data {
                    TileDataCache.shared.set(data, for: url)
                }
                group.leave()
            }.resume()
        }

        group.notify(queue: .main) { completion() }
    }

    /// Prefetches all frames in parallel into TileDataCache without adding overlays to the map.
    private func prefetchFramesSequentially(_ frameIndices: [Int], tilePaths: [MKTileOverlayPath]) {
        let startTime = Date()
        let totalFrames = frameIndices.count
        var completedCount = 0
        print("[Radar] parallel prefetch starting — \(totalFrames) frames")

        for index in frameIndices {
            prefetchTilesForFrame(index, tilePaths: tilePaths, session: prefetchSession) { [weak self] in
                guard let self = self else { return }

                completedCount += 1
                if completedCount == totalFrames {
                    let elapsed = Date().timeIntervalSince(startTime)
                    print("[Radar] parallel prefetch complete — \(totalFrames) frames in \(String(format: "%.1f", elapsed))s")
                    self.playPauseButton.isEnabled = true
                }
            }
        }
    }

    private func visibleTilePaths() -> [MKTileOverlayPath] {
        let mapRect = mapView.visibleMapRect
        let zoomScale = Double(mapView.bounds.width) / mapRect.size.width
        let zoomLevel = max(0, Int(log2(zoomScale * MKMapSize.world.width / 256.0)))

        let tileCount = Double(1 << zoomLevel)
        let minX = max(0, Int(mapRect.origin.x / MKMapSize.world.width * tileCount))
        let maxX = min(Int(tileCount) - 1, Int((mapRect.origin.x + mapRect.size.width) / MKMapSize.world.width * tileCount))
        let minY = max(0, Int(mapRect.origin.y / MKMapSize.world.height * tileCount))
        let maxY = min(Int(tileCount) - 1, Int((mapRect.origin.y + mapRect.size.height) / MKMapSize.world.height * tileCount))

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
        // Ensure all overlays are added before animating
        addRemainingOverlays()

        isPlaying = true
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, !self.timeSteps.isEmpty else { return }
            self.currentFrameIndex = (self.currentFrameIndex + 1) % self.timeSteps.count
            self.timeSlider.value = Float(self.currentFrameIndex)
            self.updateTimeLabel()
            self.applyCurrentFrame()
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
        applyCurrentFrame()
    }

    // MARK: - MKMapViewDelegate

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
