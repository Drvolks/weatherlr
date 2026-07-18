//
//  RadarImagery.swift
//  weatherlr
//
//  Created by drvolks on 2026-07-18.
//  Copyright © 2026 drvolks. All rights reserved.
//

import Foundation

/// Fixed EPSG:3857 (Web Mercator) viewport for a composited radar image
/// request, built from a city coordinate instead of an `MKMapRect` so it can
/// be used on platforms without MapKit rendering (watchOS).
struct RadarMercatorViewport: Equatable, Sendable {
    private static let originShift = 20037508.342789244

    let minX: Double
    let minY: Double
    let maxX: Double
    let maxY: Double
    let pixelWidth: Int
    let pixelHeight: Int

    /// - Parameter widthMeters: total ground span of the image width; the
    ///   height span is derived from the pixel aspect ratio so the projection
    ///   is not distorted.
    init?(centerLatitude: Double, centerLongitude: Double, widthMeters: Double, pixelWidth: Int, pixelHeight: Int) {
        guard centerLatitude.isFinite, centerLongitude.isFinite,
              abs(centerLatitude) < 85.06, abs(centerLongitude) <= 180,
              widthMeters > 0, pixelWidth > 0, pixelHeight > 0 else {
            return nil
        }

        let centerX = centerLongitude / 180 * Self.originShift
        let centerY = log(tan((90 + centerLatitude) * .pi / 360)) / .pi * Self.originShift
        let halfWidth = widthMeters / 2
        let halfHeight = halfWidth * Double(pixelHeight) / Double(pixelWidth)

        self.minX = centerX - halfWidth
        self.maxX = centerX + halfWidth
        self.minY = centerY - halfHeight
        self.maxY = centerY + halfHeight
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

/// WMS / map-service URL construction and response validation shared by the
/// iOS and watchOS radar displays.
enum RadarImagery {
    /// PNG file signature (first 8 bytes): 89 50 4E 47 0D 0A 1A 0A.
    private static let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    /// Environment Canada GeoMet GetMap request for one radar time step over
    /// the viewport, matching the request built by `RadarViewController`.
    static func radarImageURL(timeStep: String, viewport: RadarMercatorViewport) -> URL? {
        var components = URLComponents(string: "https://geo.weather.gc.ca/geomet")
        components?.queryItems = [
            URLQueryItem(name: "SERVICE", value: "WMS"),
            URLQueryItem(name: "VERSION", value: "1.3.0"),
            URLQueryItem(name: "REQUEST", value: "GetMap"),
            URLQueryItem(name: "LAYERS", value: "RADAR_1KM_RRAI"),
            URLQueryItem(name: "CRS", value: "EPSG:3857"),
            URLQueryItem(name: "BBOX", value: "\(viewport.minX),\(viewport.minY),\(viewport.maxX),\(viewport.maxY)"),
            URLQueryItem(name: "WIDTH", value: "\(viewport.pixelWidth)"),
            URLQueryItem(name: "HEIGHT", value: "\(viewport.pixelHeight)"),
            URLQueryItem(name: "FORMAT", value: "image/png"),
            URLQueryItem(name: "TRANSPARENT", value: "TRUE"),
            URLQueryItem(name: "TIME", value: timeStep),
        ]
        return components?.url
    }

    /// NRCan CBMT basemap export over the exact same bbox/size as the radar
    /// image, so the two layers align pixel-perfect when stacked.
    /// (`maps.geogratis.gc.ca/wms/CBMT` is retired; `maps-cartes.services.geo.ca`
    /// is where its successor ArcGIS service resolves.)
    static func basemapURL(viewport: RadarMercatorViewport) -> URL? {
        var components = URLComponents(string: "https://maps-cartes.services.geo.ca/server2_serveur2/rest/services/BaseMaps/CBMT_CBCT_GEOM_3857/MapServer/export")
        components?.queryItems = [
            URLQueryItem(name: "bbox", value: "\(viewport.minX),\(viewport.minY),\(viewport.maxX),\(viewport.maxY)"),
            URLQueryItem(name: "bboxSR", value: "3857"),
            URLQueryItem(name: "imageSR", value: "3857"),
            URLQueryItem(name: "size", value: "\(viewport.pixelWidth),\(viewport.pixelHeight)"),
            URLQueryItem(name: "format", value: "png"),
            URLQueryItem(name: "transparent", value: "false"),
            URLQueryItem(name: "f", value: "image"),
        ]
        return components?.url
    }

    /// Returns `data` only when the response looks like a real PNG worth
    /// displaying: an HTTP 2xx response whose body begins with the PNG
    /// signature. Rejects rate-limit / error responses and HTML error pages.
    static func validatePNG(_ data: Data?, _ response: URLResponse?) -> Data? {
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

    /// Formats an ISO8601 radar time step as a local "HH:mm zzz" label,
    /// matching the iOS radar time label.
    static func localTimeLabel(isoTimeStep: String, timeZone: TimeZone = .current) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        guard let date = isoFormatter.date(from: isoTimeStep) else {
            return "--:--"
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        displayFormatter.timeZone = timeZone
        let timeString = displayFormatter.string(from: date)

        let tzFormatter = DateFormatter()
        tzFormatter.dateFormat = "zzz"
        tzFormatter.timeZone = timeZone
        let tzString = tzFormatter.string(from: date)

        return "\(timeString) \(tzString)"
    }
}
