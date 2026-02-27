//
//  RadarTimeStepCache.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2024-01-01.
//  Copyright © 2024 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import CoreLocation

class RadarTimeStepCache: @unchecked Sendable {
    static let shared = RadarTimeStepCache()

    private let lock = NSLock()
    private var cachedSteps: [String] = []
    private var fetchDate: Date?
    private var isFetching = false
    private var tileSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache.shared
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    private init() {}

    func preload() {
        lock.lock()
        let shouldFetch: Bool
        if isFetching {
            print("[RadarCache] preload skipped — already fetching")
            shouldFetch = false
        } else if let fetchDate = fetchDate, Date().timeIntervalSince(fetchDate) < 300 {
            print("[RadarCache] preload skipped — cache is \(Int(Date().timeIntervalSince(fetchDate)))s old (< 300s)")
            shouldFetch = false
        } else {
            print("[RadarCache] preload starting fetch...")
            shouldFetch = true
            isFetching = true
        }
        lock.unlock()

        guard shouldFetch else { return }

        let startTime = Date()
        let urlString = "https://geo.weather.gc.ca/geomet?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities&LAYERS=RADAR_1KM_RRAI"
        guard let url = URL(string: urlString) else {
            print("[RadarCache] preload failed — invalid URL")
            lock.lock()
            isFetching = false
            lock.unlock()
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            let elapsed = Date().timeIntervalSince(startTime)
            guard let self = self else {
                print("[RadarCache] preload failed — self deallocated after \(String(format: "%.1f", elapsed))s")
                return
            }
            guard let data = data, error == nil else {
                print("[RadarCache] preload failed — \(error?.localizedDescription ?? "no data") after \(String(format: "%.1f", elapsed))s")
                self.lock.lock()
                self.isFetching = false
                self.lock.unlock()
                return
            }

            let parser = TimeDimensionParser(data: data)
            let steps = parser.parse()

            self.lock.lock()
            if !steps.isEmpty {
                self.cachedSteps = steps
                self.fetchDate = Date()
                print("[RadarCache] preload complete — \(steps.count) steps cached in \(String(format: "%.1f", elapsed))s")
                let lastStep = steps.last
                self.lock.unlock()
                if let time = lastStep {
                    self.preloadTiles(for: time)
                }
            } else {
                print("[RadarCache] preload failed — parsed 0 steps from \(data.count) bytes in \(String(format: "%.1f", elapsed))s")
                self.isFetching = false
                self.lock.unlock()
            }
        }.resume()
    }

    private func preloadTiles(for timeStep: String) {
        let city = PreferenceHelper.getCityToUse()
        guard let lat = Double(city.latitude), let lon = Double(city.longitude) else {
            print("[RadarCache] tile preload skipped — no city coordinates")
            isFetching = false
            return
        }

        let zoom = 7
        let centerTileX = lonToTileX(lon: lon, zoom: zoom)
        let centerTileY = latToTileY(lat: lat, zoom: zoom)

        var tileURLs: [URL] = []
        for dx in -1...1 {
            for dy in -1...1 {
                let tx = centerTileX + dx
                let ty = centerTileY + dy
                let bbox = tileBBox(x: tx, y: ty, z: zoom)
                let urlString = "https://geo.weather.gc.ca/geomet?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=RADAR_1KM_RRAI&CRS=EPSG:3857&BBOX=\(bbox.minX),\(bbox.minY),\(bbox.maxX),\(bbox.maxY)&WIDTH=256&HEIGHT=256&FORMAT=image/png&TRANSPARENT=TRUE&TIME=\(timeStep)"
                if let url = URL(string: urlString) {
                    tileURLs.append(url)
                }
            }
        }

        print("[RadarCache] preloading \(tileURLs.count) tiles at zoom \(zoom) around (\(lat), \(lon))...")
        let startTime = Date()
        let group = DispatchGroup()

        for url in tileURLs {
            group.enter()
            tileSession.dataTask(with: url) { data, response, _ in
                if let data = data, let response = response {
                    let cached = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cached, for: URLRequest(url: url))
                }
                group.leave()
            }.resume()
        }

        group.notify(queue: .global()) { [weak self] in
            let elapsed = Date().timeIntervalSince(startTime)
            print("[RadarCache] tile preload complete — \(tileURLs.count) tiles in \(String(format: "%.1f", elapsed))s")
            self?.lock.lock()
            self?.isFetching = false
            self?.lock.unlock()
        }
    }

    private static let originShift = 20037508.342789244

    private func lonToTileX(lon: Double, zoom: Int) -> Int {
        return Int(floor((lon + 180.0) / 360.0 * pow(2.0, Double(zoom))))
    }

    private func latToTileY(lat: Double, zoom: Int) -> Int {
        let latRad = lat * .pi / 180.0
        return Int(floor((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / .pi) / 2.0 * pow(2.0, Double(zoom))))
    }

    private func tileBBox(x: Int, y: Int, z: Int) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        let tileSize = (2 * RadarTimeStepCache.originShift) / pow(2.0, Double(z))
        let minX = Double(x) * tileSize - RadarTimeStepCache.originShift
        let maxX = minX + tileSize
        let maxY = RadarTimeStepCache.originShift - Double(y) * tileSize
        let minY = maxY - tileSize
        return (minX, minY, maxX, maxY)
    }

    func getCachedSteps() -> [String]? {
        lock.lock()
        defer { lock.unlock() }
        guard !cachedSteps.isEmpty,
              let fetchDate = fetchDate,
              Date().timeIntervalSince(fetchDate) < 1800 else {
            print("[RadarCache] getCachedSteps — cache miss (empty=\(cachedSteps.isEmpty), age=\(fetchDate.map { "\(Int(Date().timeIntervalSince($0)))s" } ?? "nil"))")
            return nil
        }
        print("[RadarCache] getCachedSteps — cache hit, \(cachedSteps.count) steps, age=\(Int(Date().timeIntervalSince(fetchDate)))s")
        return cachedSteps
    }
}

// MARK: - TimeDimensionParser

class TimeDimensionParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var foundDimension = false
    private var dimensionValue = ""
    private var timeSteps: [String] = []

    init(data: Data) {
        self.data = data
    }

    func parse() -> [String] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return timeSteps
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "Dimension" && attributeDict["name"] == "time" {
            foundDimension = true
            dimensionValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if foundDimension {
            dimensionValue += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "Dimension" && foundDimension {
            foundDimension = false
            let trimmed = dimensionValue.trimmingCharacters(in: .whitespacesAndNewlines)
            timeSteps = generateTimeSteps(from: trimmed)
            parser.abortParsing()
        }
    }

    private func generateTimeSteps(from dimension: String) -> [String] {
        let parts = dimension.split(separator: "/")
        guard parts.count == 3 else { return [] }

        let startStr = String(parts[0])
        let endStr = String(parts[1])
        let intervalStr = String(parts[2])

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        guard let startDate = formatter.date(from: startStr),
              let endDate = formatter.date(from: endStr),
              let intervalSeconds = parseISO8601Duration(intervalStr) else {
            return []
        }

        var steps: [String] = []
        var current = startDate
        while current <= endDate {
            steps.append(formatter.string(from: current))
            current = current.addingTimeInterval(intervalSeconds)
        }
        return steps
    }

    private func parseISO8601Duration(_ duration: String) -> TimeInterval? {
        var str = duration
        guard str.hasPrefix("PT") else { return nil }
        str.removeFirst(2)

        var totalSeconds: TimeInterval = 0
        var numberStr = ""

        for char in str {
            if char.isNumber {
                numberStr.append(char)
            } else {
                guard let value = Double(numberStr) else { return nil }
                switch char {
                case "H": totalSeconds += value * 3600
                case "M": totalSeconds += value * 60
                case "S": totalSeconds += value
                default: return nil
                }
                numberStr = ""
            }
        }

        return totalSeconds > 0 ? totalSeconds : nil
    }
}
