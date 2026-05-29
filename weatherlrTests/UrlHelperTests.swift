//
//  UrlHelperTests.swift
//  weatherlrTests
//

import XCTest
@testable import weatherlr

class UrlHelperTests: XCTestCase {

    private func city(id: String) -> City {
        return City(id: id, frenchName: "Test", englishName: "Test",
                    province: "QC", radarId: "", latitude: "", longitude: "")
    }

    func testGetUrlDefault() {
        let url = UrlHelper.getUrl(city(id: "qc-147"))
        XCTAssertEqual("https://api.weather.gc.ca/collections/citypageweather-realtime/items/qc-147?f=json", url)
    }

    func testGetUrlWithEnglish() {
        let url = UrlHelper.getUrl(city(id: "qc-147"), lang: .English)
        XCTAssertTrue(url.contains("items/qc-147"))
        XCTAssertTrue(url.contains("lang=en-CA"))
        XCTAssertTrue(url.contains("f=json"))
    }

    func testGetUrlWithFrench() {
        let url = UrlHelper.getUrl(city(id: "on-143"), lang: .French)
        XCTAssertTrue(url.contains("items/on-143"))
        XCTAssertTrue(url.contains("lang=fr-CA"))
    }

    func testGetUrlHandlesEmptyId() {
        let url = UrlHelper.getUrl(city(id: ""))
        XCTAssertTrue(url.contains("items/?f=json"))
    }

    // MARK: - Alert detail (#20)

    func testGetAlertAnchorFromWarningUrl() {
        let url = "https://weather.gc.ca/warnings/report_e.html?qcrm12#1510018161054675805202605280504"
        XCTAssertEqual("1510018161054675805202605280504",
                       UrlHelper.getAlertAnchor(fromWarningUrl: url))
    }

    func testGetAlertAnchorReturnsNilWithoutAnchor() {
        XCTAssertNil(UrlHelper.getAlertAnchor(fromWarningUrl: "https://weather.gc.ca/warnings/"))
        XCTAssertNil(UrlHelper.getAlertAnchor(fromWarningUrl: "https://weather.gc.ca/warnings/report_e.html#"))
        XCTAssertNil(UrlHelper.getAlertAnchor(fromWarningUrl: ""))
    }

    func testGetAlertDetailUrlEncodesFilter() {
        let url = UrlHelper.getAlertDetailUrl(anchor: "1510018161054675805202605280504")
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.hasPrefix("https://api.weather.gc.ca/collections/weather-alerts/items?f=json&limit=1&filter="))
        // The CQL filter must be percent-encoded: space, quote and % wildcard.
        XCTAssertTrue(url!.contains("id%20LIKE%20%27"))
        XCTAssertTrue(url!.contains("1510018161054675805202605280504"))
        XCTAssertTrue(url!.contains("%25%27")) // trailing %'
        XCTAssertFalse(url!.contains(" "))     // no raw spaces
    }
}
