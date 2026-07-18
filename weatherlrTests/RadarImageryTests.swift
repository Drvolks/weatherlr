//
//  RadarImageryTests.swift
//  weatherlrTests
//
//  Covers RadarMercatorViewport (Web Mercator bbox math shared with the
//  watch radar view) and the RadarImagery URL builders / PNG validation.
//

import XCTest
@testable import weatherlr

final class RadarImageryTests: XCTestCase {

    // Montréal
    private let montrealLat = 45.5088
    private let montrealLon = -73.5878

    private func montrealViewport(widthMeters: Double = 240_000,
                                  pixelWidth: Int = 400,
                                  pixelHeight: Int = 480) -> RadarMercatorViewport {
        RadarMercatorViewport(centerLatitude: montrealLat,
                              centerLongitude: montrealLon,
                              widthMeters: widthMeters,
                              pixelWidth: pixelWidth,
                              pixelHeight: pixelHeight)!
    }

    // MARK: - Viewport math

    func testMontrealCenterProjectsToKnownMercatorCoordinates() {
        let viewport = montrealViewport()
        let centerX = (viewport.minX + viewport.maxX) / 2
        let centerY = (viewport.minY + viewport.maxY) / 2

        // Reference values from the standard EPSG:3857 forward projection.
        XCTAssertEqual(centerX, -8_191_745, accuracy: 1_000)
        XCTAssertEqual(centerY, 5_702_871, accuracy: 1_000)
    }

    func testBboxIsSymmetricAroundCenterWithRequestedWidth() {
        let viewport = montrealViewport(widthMeters: 240_000)
        XCTAssertEqual(viewport.maxX - viewport.minX, 240_000, accuracy: 0.001)
    }

    func testHeightSpanIsScaledByPixelAspectRatio() {
        let viewport = montrealViewport(widthMeters: 240_000, pixelWidth: 400, pixelHeight: 480)
        let expectedHeight = 240_000 * 480.0 / 400.0
        XCTAssertEqual(viewport.maxY - viewport.minY, expectedHeight, accuracy: 0.001)
    }

    func testEquatorCenterProjectsToOrigin() {
        let viewport = RadarMercatorViewport(centerLatitude: 0, centerLongitude: 0,
                                             widthMeters: 100_000, pixelWidth: 256, pixelHeight: 256)!
        XCTAssertEqual((viewport.minX + viewport.maxX) / 2, 0, accuracy: 0.001)
        XCTAssertEqual((viewport.minY + viewport.maxY) / 2, 0, accuracy: 0.001)
    }

    func testInvalidInputsReturnNil() {
        XCTAssertNil(RadarMercatorViewport(centerLatitude: 90, centerLongitude: 0,
                                           widthMeters: 100_000, pixelWidth: 256, pixelHeight: 256))
        XCTAssertNil(RadarMercatorViewport(centerLatitude: .nan, centerLongitude: 0,
                                           widthMeters: 100_000, pixelWidth: 256, pixelHeight: 256))
        XCTAssertNil(RadarMercatorViewport(centerLatitude: 45, centerLongitude: 0,
                                           widthMeters: 0, pixelWidth: 256, pixelHeight: 256))
        XCTAssertNil(RadarMercatorViewport(centerLatitude: 45, centerLongitude: 0,
                                           widthMeters: 100_000, pixelWidth: 0, pixelHeight: 256))
    }

    // MARK: - URL construction

    private func queryItems(of url: URL) -> [String: String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var items: [String: String] = [:]
        for item in components?.queryItems ?? [] {
            items[item.name] = item.value
        }
        return items
    }

    func testRadarImageURLContainsExpectedQueryItems() throws {
        let viewport = montrealViewport()
        let url = try XCTUnwrap(RadarImagery.radarImageURL(timeStep: "2026-07-18T12:00:00Z", viewport: viewport))

        XCTAssertEqual(url.host, "geo.weather.gc.ca")
        let items = queryItems(of: url)
        XCTAssertEqual(items["REQUEST"], "GetMap")
        XCTAssertEqual(items["LAYERS"], "RADAR_1KM_RRAI")
        XCTAssertEqual(items["CRS"], "EPSG:3857")
        XCTAssertEqual(items["WIDTH"], "400")
        XCTAssertEqual(items["HEIGHT"], "480")
        XCTAssertEqual(items["TRANSPARENT"], "TRUE")
        XCTAssertEqual(items["TIME"], "2026-07-18T12:00:00Z")
        XCTAssertEqual(items["BBOX"], "\(viewport.minX),\(viewport.minY),\(viewport.maxX),\(viewport.maxY)")
    }

    func testBasemapURLSharesBboxAndSizeWithRadarImage() throws {
        let viewport = montrealViewport()
        let url = try XCTUnwrap(RadarImagery.basemapURL(viewport: viewport))

        XCTAssertEqual(url.host, "maps-cartes.services.geo.ca")
        let items = queryItems(of: url)
        XCTAssertEqual(items["bbox"], "\(viewport.minX),\(viewport.minY),\(viewport.maxX),\(viewport.maxY)")
        XCTAssertEqual(items["bboxSR"], "3857")
        XCTAssertEqual(items["imageSR"], "3857")
        XCTAssertEqual(items["size"], "400,480")
        XCTAssertEqual(items["f"], "image")
    }

    // MARK: - PNG validation (mirrors WMSTileOverlayTests)

    private let url = URL(string: "https://geo.weather.gc.ca/geomet")!

    private var pngData: Data {
        Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x01])
    }

    private func httpResponse(_ statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
    }

    func testValidPngWith200IsAccepted() {
        XCTAssertEqual(RadarImagery.validatePNG(pngData, httpResponse(200)), pngData)
    }

    func testValidPngWithRateLimitIsRejected() {
        XCTAssertNil(RadarImagery.validatePNG(pngData, httpResponse(429)))
    }

    func testValidPngWithServerErrorIsRejected() {
        XCTAssertNil(RadarImagery.validatePNG(pngData, httpResponse(503)))
    }

    func testHtmlErrorPageWith200IsRejected() {
        let html = Data("<html><body>Service unavailable</body></html>".utf8)
        XCTAssertNil(RadarImagery.validatePNG(html, httpResponse(200)))
    }

    func testEmptyBodyIsRejected() {
        XCTAssertNil(RadarImagery.validatePNG(Data(), httpResponse(200)))
    }

    func testNilDataIsRejected() {
        XCTAssertNil(RadarImagery.validatePNG(nil, httpResponse(200)))
    }

    // MARK: - Time label

    func testLocalTimeLabelFormatsInGivenTimeZone() {
        // The timezone suffix ("EDT" / "HAE") depends on the device locale,
        // so only the time portion is asserted exactly.
        let label = RadarImagery.localTimeLabel(isoTimeStep: "2026-07-18T16:30:00Z",
                                                timeZone: TimeZone(identifier: "America/Montreal")!)
        XCTAssertTrue(label.hasPrefix("12:30 "), "unexpected label: \(label)")
        XCTAssertGreaterThan(label.count, "12:30 ".count)
    }

    func testLocalTimeLabelWithInvalidInputReturnsPlaceholder() {
        XCTAssertEqual(RadarImagery.localTimeLabel(isoTimeStep: "not-a-date"), "--:--")
    }
}
