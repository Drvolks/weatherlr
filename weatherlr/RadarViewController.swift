//
//  RadarViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-16.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class RadarViewController: UIViewController, MKMapViewDelegate {

    var city: City?
    private var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    private var didCenterOnUser = false

    private var overlay: WMSTileOverlay!
    private var tileRenderer: MKTileOverlayRenderer!

    private var timeSteps: [String] = []
    private var currentFrameIndex = 0
    private var animationTimer: Timer?
    private var isPlaying = false

    private var playPauseButton: UIButton!
    private var timeSlider: UISlider!
    private var timeLabel: UILabel!
    private var controlBar: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Radar".localized()

        mapView = MKMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.mapType = .hybrid
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true
        mapView.delegate = self
        view.addSubview(mapView)

        overlay = WMSTileOverlay()
        overlay.tileSize = CGSize(width: 256, height: 256)
        mapView.addOverlay(overlay, level: .aboveRoads)

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

        setupControlBar()
        fetchTimeSteps()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
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
        self.timeSteps = steps
        self.currentFrameIndex = steps.count - 1

        self.timeSlider.maximumValue = Float(steps.count - 1)
        self.timeSlider.value = Float(self.currentFrameIndex)
        self.timeSlider.isEnabled = true
        self.playPauseButton.isEnabled = true

        self.updateTimeLabel()
        self.applyCurrentFrame()
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
        guard currentFrameIndex < timeSteps.count else { return }
        overlay.currentTime = timeSteps[currentFrameIndex]
        tileRenderer.reloadData()
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
        isPlaying = true
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
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
        if let tileOverlay = overlay as? MKTileOverlay {
            let renderer = MKTileOverlayRenderer(overlay: tileOverlay)
            self.tileRenderer = renderer
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

