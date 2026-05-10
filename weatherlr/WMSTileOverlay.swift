//
//  WMSTileOverlay.swift
//  weatherlr
//
//  Created by drvolks on 2025-02-13.
//  Copyright © 2025 drvolks. All rights reserved.
//

import MapKit

extension URLCache {
    static let radarTileCache: URLCache = {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let directory = cachesDir?.appendingPathComponent("RadarTiles", isDirectory: true)
        return URLCache(memoryCapacity: 50 * 1024 * 1024,
                        diskCapacity: 200 * 1024 * 1024,
                        directory: directory)
    }()
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

        if let cached = TileDataCache.shared.get(tileURL) {
            result(cached, nil)
            return
        }

        let request = URLRequest(url: tileURL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        WMSTileOverlay.sharedTileSession.dataTask(with: request) { data, _, error in
            if let data = data {
                TileDataCache.shared.set(data, for: tileURL)
            }
            result(data, error)
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
