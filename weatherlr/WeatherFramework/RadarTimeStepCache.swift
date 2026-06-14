//
//  RadarTimeStepCache.swift
//  weatherlr
//
//  Created by drvolks on 2024-01-01.
//  Copyright © 2024 drvolks. All rights reserved.
//

import Foundation

#if os(iOS)
extension URLCache {
    static let radarTileCache: URLCache = {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        // "V2": bumped from "RadarTiles" to abandon any poisoned tiles cached by
        // earlier builds that stored non-PNG responses.
        let directory = cachesDir?.appendingPathComponent("RadarTilesV2", isDirectory: true)
        return URLCache(memoryCapacity: 50 * 1024 * 1024,
                        diskCapacity: 200 * 1024 * 1024,
                        directory: directory)
    }()
}

private final class RadarTileDownloadStats: @unchecked Sendable {
    private let lock = NSLock()
    private var downloadedCount = 0
    private var rejectedCount = 0

    func recordDownloaded() {
        lock.lock()
        downloadedCount += 1
        lock.unlock()
    }

    func recordRejected() {
        lock.lock()
        rejectedCount += 1
        lock.unlock()
    }

    func snapshot() -> (downloaded: Int, rejected: Int) {
        lock.lock()
        defer { lock.unlock() }
        return (downloadedCount, rejectedCount)
    }
}
#endif

class RadarTimeStepCache: @unchecked Sendable {
    static let shared = RadarTimeStepCache()

    /// Posted on the main queue whenever cached radar time steps become
    /// available (either an initial fetch completing or a refresh). Observers
    /// can use this to enable radar UI once `getCachedSteps()` returns data.
    static let didUpdateNotification = Notification.Name("RadarTimeStepCacheDidUpdate")

    private enum StorageKeys {
        static let steps = "radarTimeSteps"
        static let date = "radarTimeStepsDate"
    }

    private let lock = NSLock()
    private var cachedSteps: [String] = []
    private var fetchDate: Date?
    private var isFetching = false

    #if os(iOS)
    private struct RadarTilePath {
        let x: Int
        let y: Int
        let z: Int
    }

    private let latestFrameTileSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 6
        config.urlCache = .radarTileCache
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    private var isPreloadingLatestFrameTiles = false
    #endif

    private init() {
        if let steps = UserDefaults.standard.stringArray(forKey: StorageKeys.steps),
           let date = UserDefaults.standard.object(forKey: StorageKeys.date) as? Date,
           !steps.isEmpty,
           Date().timeIntervalSince(date) < 1800 {
            cachedSteps = steps
            fetchDate = date
        }
    }

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
                UserDefaults.standard.set(steps, forKey: StorageKeys.steps)
                UserDefaults.standard.set(self.fetchDate, forKey: StorageKeys.date)
                print("[RadarCache] preload complete — \(steps.count) steps cached in \(String(format: "%.1f", elapsed))s")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: RadarTimeStepCache.didUpdateNotification, object: nil)
                }
            } else {
                print("[RadarCache] preload failed — parsed 0 steps from \(data.count) bytes in \(String(format: "%.1f", elapsed))s")
            }
            self.isFetching = false
            self.lock.unlock()
        }.resume()
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

    #if os(iOS)
    func preloadLatestFrameTiles(
        for city: City,
        cachedTile: @escaping @Sendable (URL) -> Data? = { _ in nil },
        storeTile: @escaping @Sendable (Data, URL) -> Void = { _, _ in }
    ) {
        guard !city.radarId.isEmpty else {
            print("[RadarCache] latest frame tile preload skipped - city has no radar")
            return
        }
        guard let lat = Double(city.latitude), let lon = Double(city.longitude) else {
            print("[RadarCache] latest frame tile preload skipped - invalid city coordinates")
            return
        }
        guard let latestStep = getCachedSteps()?.last else {
            print("[RadarCache] latest frame tile preload skipped - time steps not cached yet")
            return
        }

        lock.lock()
        guard !isPreloadingLatestFrameTiles else {
            lock.unlock()
            print("[RadarCache] latest frame tile preload skipped - already preloading")
            return
        }
        isPreloadingLatestFrameTiles = true
        lock.unlock()

        let startTime = Date()
        let tilePaths = radarTilePaths(centerLat: lat, centerLon: lon, zoom: 7, halfSpanKm: 200)
        guard !tilePaths.isEmpty else {
            finishLatestFrameTilePreload()
            print("[RadarCache] latest frame tile preload skipped - no tile paths")
            return
        }

        var pendingRequests: [(url: URL, request: URLRequest)] = []
        var cachedCount = 0

        for path in tilePaths {
            guard let url = radarTileURL(for: path, timeStep: latestStep) else { continue }
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)

            if cachedTile(url) != nil {
                cachedCount += 1
                continue
            }

            if let cachedResponse = URLCache.radarTileCache.cachedResponse(for: request),
               let validData = Self.validateTile(cachedResponse.data, cachedResponse.response) {
                storeTile(validData, url)
                cachedCount += 1
                continue
            }

            URLCache.radarTileCache.removeCachedResponse(for: request)
            pendingRequests.append((url, request))
        }

        guard !pendingRequests.isEmpty else {
            finishLatestFrameTilePreload()
            let elapsed = Date().timeIntervalSince(startTime)
            print("[RadarCache] latest frame tile preload complete - \(cachedCount)/\(tilePaths.count) valid tiles already cached in \(String(format: "%.1f", elapsed))s")
            return
        }

        let group = DispatchGroup()
        let stats = RadarTileDownloadStats()

        for (url, request) in pendingRequests {
            group.enter()
            latestFrameTileSession.dataTask(with: request) { data, response, _ in
                if let validData = Self.validateTile(data, response) {
                    storeTile(validData, url)
                    if let response {
                        URLCache.radarTileCache.storeCachedResponse(CachedURLResponse(response: response, data: validData), for: request)
                    }
                    stats.recordDownloaded()
                } else {
                    URLCache.radarTileCache.removeCachedResponse(for: request)
                    stats.recordRejected()
                }
                group.leave()
            }.resume()
        }

        group.notify(queue: .main) { [weak self] in
            let (downloaded, rejected) = stats.snapshot()

            self?.finishLatestFrameTilePreload()
            let validCount = cachedCount + downloaded
            let elapsed = Date().timeIntervalSince(startTime)
            print("[RadarCache] latest frame tile preload complete - \(validCount)/\(tilePaths.count) valid tiles in \(String(format: "%.1f", elapsed))s (cached=\(cachedCount), downloaded=\(downloaded), rejected=\(rejected))")
        }
    }

    private func finishLatestFrameTilePreload() {
        lock.lock()
        isPreloadingLatestFrameTiles = false
        lock.unlock()
    }

    private func radarTilePaths(centerLat: Double, centerLon: Double,
                                zoom: Int, halfSpanKm: Double) -> [RadarTilePath] {
        let earthRadiusMeters = 6_378_137.0
        let latDelta = (halfSpanKm * 1000) / earthRadiusMeters * (180 / .pi)
        let lonDelta = latDelta / max(cos(centerLat * .pi / 180), 0.01)

        let minLat = max(-85.0511, centerLat - latDelta)
        let maxLat = min(85.0511, centerLat + latDelta)
        let minLon = max(-180.0, centerLon - lonDelta)
        let maxLon = min(180.0, centerLon + lonDelta)

        let minTile = latLonToTileXY(lat: maxLat, lon: minLon, zoom: zoom)
        let maxTile = latLonToTileXY(lat: minLat, lon: maxLon, zoom: zoom)

        guard minTile.x <= maxTile.x, minTile.y <= maxTile.y else { return [] }

        var paths: [RadarTilePath] = []
        for x in minTile.x...maxTile.x {
            for y in minTile.y...maxTile.y {
                paths.append(RadarTilePath(x: x, y: y, z: zoom))
            }
        }
        return paths
    }

    private func latLonToTileXY(lat: Double, lon: Double, zoom: Int) -> (x: Int, y: Int) {
        let n = pow(2.0, Double(zoom))
        let x = ((lon + 180.0) / 360.0 * n).rounded(.down)

        let latRad = lat * .pi / 180
        let yRaw = (1 - log(tan(latRad) + 1 / cos(latRad)) / .pi) / 2 * n
        let y = yRaw.rounded(.down)

        let maxIndex = Int(n) - 1
        return (x: max(0, min(Int(x), maxIndex)),
                y: max(0, min(Int(y), maxIndex)))
    }

    private func radarTileURL(for path: RadarTilePath, timeStep: String) -> URL? {
        let bbox = tileBBox(x: path.x, y: path.y, z: path.z)
        let urlString = "https://geo.weather.gc.ca/geomet?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=RADAR_1KM_RRAI&CRS=EPSG:3857&BBOX=\(bbox.minX),\(bbox.minY),\(bbox.maxX),\(bbox.maxY)&WIDTH=256&HEIGHT=256&FORMAT=image/png&TRANSPARENT=TRUE&TIME=\(timeStep)"
        return URL(string: urlString)
    }

    private func tileBBox(x: Int, y: Int, z: Int) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        let originShift = 20037508.342789244
        let tileSize = (2 * originShift) / pow(2.0, Double(z))
        let minX = Double(x) * tileSize - originShift
        let maxX = minX + tileSize
        let maxY = originShift - Double(y) * tileSize
        let minY = maxY - tileSize
        return (minX, minY, maxX, maxY)
    }

    private static let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    private static func validateTile(_ data: Data?, _ response: URLResponse?) -> Data? {
        guard let data, data.count >= pngSignature.count,
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            return nil
        }
        for (offset, byte) in pngSignature.enumerated() where data[data.startIndex + offset] != byte {
            return nil
        }
        return data
    }
    #endif

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
