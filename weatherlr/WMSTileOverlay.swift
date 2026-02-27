//
//  WMSTileOverlay.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

import MapKit

class WMSTileOverlay: MKTileOverlay {
    private static let originShift = 20037508.342789244

    var currentTime: String?

    init() {
        super.init(urlTemplate: nil)
        canReplaceMapContent = false
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let bbox = tileBBox(x: path.x, y: path.y, z: path.z)
        var urlString = "https://geo.weather.gc.ca/geomet?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=RADAR_1KM_RRAI&CRS=EPSG:3857&BBOX=\(bbox.minX),\(bbox.minY),\(bbox.maxX),\(bbox.maxY)&WIDTH=256&HEIGHT=256&FORMAT=image/png&TRANSPARENT=TRUE"
        if let time = currentTime {
            urlString += "&TIME=\(time)"
        }
        return URL(string: urlString)!
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let tileURL = url(forTilePath: path)
        let request = URLRequest(url: tileURL)

        if let cached = URLCache.shared.cachedResponse(for: request) {
            result(cached.data, nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response {
                let cachedResponse = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cachedResponse, for: request)
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
