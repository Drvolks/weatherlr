//
//  WMSTileOverlayTests.swift
//  weatherlrTests
//
//  Covers WMSTileOverlay.validate, which guards the radar tile caches against
//  rate-limit / error responses that would otherwise render as empty tiles
//  (see issue #23).
//

import XCTest
@testable import weatherlr

final class WMSTileOverlayTests: XCTestCase {

    private let url = URL(string: "https://geo.weather.gc.ca/geomet")!

    /// First 8 bytes of any PNG file, plus a couple of payload bytes.
    private var pngData: Data {
        Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x01])
    }

    private func httpResponse(_ statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
    }

    func testValidPngWith200IsAccepted() {
        XCTAssertEqual(WMSTileOverlay.validate(pngData, httpResponse(200)), pngData)
    }

    func testValidPngWithRateLimitIsRejected() {
        XCTAssertNil(WMSTileOverlay.validate(pngData, httpResponse(429)))
    }

    func testValidPngWithServerErrorIsRejected() {
        XCTAssertNil(WMSTileOverlay.validate(pngData, httpResponse(503)))
    }

    func testHtmlErrorPageWith200IsRejected() {
        let html = Data("<html><body>Service unavailable</body></html>".utf8)
        XCTAssertNil(WMSTileOverlay.validate(html, httpResponse(200)))
    }

    func testEmptyBodyIsRejected() {
        XCTAssertNil(WMSTileOverlay.validate(Data(), httpResponse(200)))
    }

    func testNilDataIsRejected() {
        XCTAssertNil(WMSTileOverlay.validate(nil, httpResponse(200)))
    }

    func testBodyShorterThanSignatureIsRejected() {
        XCTAssertNil(WMSTileOverlay.validate(Data([0x89, 0x50, 0x4E]), httpResponse(200)))
    }

    func testNonHttpResponseIsRejected() {
        let response = URLResponse(url: url, mimeType: "image/png", expectedContentLength: 10, textEncodingName: nil)
        XCTAssertNil(WMSTileOverlay.validate(pngData, response))
    }
}
