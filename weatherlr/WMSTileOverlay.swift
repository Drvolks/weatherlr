//
//  WMSTileOverlay.swift
//  weatherlr
//
//  Created by drvolks on 2025-02-13.
//  Copyright © 2025 drvolks. All rights reserved.
//

import MapKit

private final class TileLoadResult: @unchecked Sendable {
    private let result: (Data?, Error?) -> Void

    init(_ result: @escaping (Data?, Error?) -> Void) {
        self.result = result
    }

    func callAsFunction(_ data: Data?, _ error: Error?) {
        result(data, error)
    }
}

class TileDataCache: @unchecked Sendable {
    static let shared = TileDataCache()
    private let lock = NSLock()
    private var store: [String: Data] = [:]
    private init() {}

    func get(_ url: URL) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return store[url.absoluteString]
    }

    func set(_ data: Data, for url: URL) {
        lock.lock()
        store[url.absoluteString] = data
        lock.unlock()
    }

    func clear() {
        lock.lock()
        store.removeAll()
        lock.unlock()
    }
}

class WMSTileOverlay: MKTileOverlay {
    private static let originShift = 20037508.342789244
    private static let sharedTileSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 6
        config.urlCache = .radarTileCache
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    let timeStep: String

    init(time: String) {
        self.timeStep = time
        super.init(urlTemplate: nil)
        canReplaceMapContent = false
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let bbox = tileBBox(x: path.x, y: path.y, z: path.z)
        let urlString = "https://geo.weather.gc.ca/geomet?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=RADAR_1KM_RRAI&CRS=EPSG:3857&BBOX=\(bbox.minX),\(bbox.minY),\(bbox.maxX),\(bbox.maxY)&WIDTH=256&HEIGHT=256&FORMAT=image/png&TRANSPARENT=TRUE&TIME=\(timeStep)"
        return URL(string: urlString)!
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let tileURL = url(forTilePath: path)
        let tileResult = TileLoadResult(result)

        if let cached = TileDataCache.shared.get(tileURL) {
            tileResult(cached, nil)
            return
        }

        let request = URLRequest(url: tileURL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        WMSTileOverlay.sharedTileSession.dataTask(with: request) { data, response, error in
            if let validData = WMSTileOverlay.validate(data, response) {
                TileDataCache.shared.set(validData, for: tileURL)
                tileResult(validData, nil)
            } else {
                // Don't cache garbage (429s, error pages, truncated bodies). Evict any
                // poisoned disk entry and report a failure so MKTileOverlayRenderer
                // re-requests this tile on the next reloadData() — see
                // RadarViewController.mapView(_:regionDidChangeAnimated:).
                WMSTileOverlay.sharedTileSession.configuration.urlCache?.removeCachedResponse(for: request)
                WMSTileOverlay.logRejectedTile(data: data, response: response, error: error)
                tileResult(nil, error)
            }
        }.resume()
    }

    private func tileBBox(x: Int, y: Int, z: Int) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        let tileSize = (2 * WMSTileOverlay.originShift) / pow(2.0, Double(z))
        let minX = Double(x) * tileSize - WMSTileOverlay.originShift
        let maxX = minX + tileSize
        let maxY = WMSTileOverlay.originShift - Double(y) * tileSize
        let minY = maxY - tileSize
        return (minX, minY, maxX, maxY)
    }
}

// MARK: - Tile Validation

extension WMSTileOverlay {
    /// PNG file signature (first 8 bytes): 89 50 4E 47 0D 0A 1A 0A.
    private static let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    /// Returns `data` only when the response looks like a real PNG tile worth
    /// caching: an HTTP 2xx response whose body begins with the PNG signature.
    /// Rejects rate-limit / error responses and HTML error pages, which would
    /// otherwise be cached and rendered as transparent (empty) tiles.
    static func validate(_ data: Data?, _ response: URLResponse?) -> Data? {
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

    /// Logs a tile that failed validation so partial-load investigations can be
    /// confirmed from device logs (matches the existing `[Radar]` log prefix).
    static func logRejectedTile(data: Data?, response: URLResponse?, error: Error?) {
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("[Radar] rejected tile — status=\(status) bytes=\(data?.count ?? 0) error=\(error?.localizedDescription ?? "none")")
    }
}
