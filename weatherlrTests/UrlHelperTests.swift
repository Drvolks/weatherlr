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
}
