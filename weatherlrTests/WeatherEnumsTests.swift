//
//  WeatherEnumsTests.swift
//  weatherlrTests
//

import XCTest
@testable import weatherlr

class WeatherEnumsTests: XCTestCase {

    func testWeatherDayRawValues() {
        XCTAssertEqual(-1, WeatherDay.now.rawValue)
        XCTAssertEqual(0, WeatherDay.today.rawValue)
        XCTAssertEqual(1, WeatherDay.tomorow.rawValue)
        XCTAssertEqual(2, WeatherDay.day2.rawValue)
        XCTAssertEqual(20, WeatherDay.day20.rawValue)
        XCTAssertEqual(-99, WeatherDay.na.rawValue)
    }

    func testWeatherDayFromRawValue() {
        XCTAssertEqual(.now, WeatherDay(rawValue: -1))
        XCTAssertEqual(.today, WeatherDay(rawValue: 0))
        XCTAssertEqual(.tomorow, WeatherDay(rawValue: 1))
        XCTAssertEqual(.day10, WeatherDay(rawValue: 10))
        XCTAssertEqual(.na, WeatherDay(rawValue: -99))
        XCTAssertNil(WeatherDay(rawValue: 21))
        XCTAssertNil(WeatherDay(rawValue: 100))
    }

    func testLanguageRawValues() {
        XCTAssertEqual("en", Language.English.rawValue)
        XCTAssertEqual("fr", Language.French.rawValue)
        XCTAssertEqual(.English, Language(rawValue: "en"))
        XCTAssertEqual(.French, Language(rawValue: "fr"))
        XCTAssertNil(Language(rawValue: "es"))
    }

    func testLanguageAllCases() {
        XCTAssertEqual(2, Language.allCases.count)
        XCTAssertTrue(Language.allCases.contains(.English))
        XCTAssertTrue(Language.allCases.contains(.French))
    }

    func testWeatherStatusAllCasesNonEmpty() {
        XCTAssertGreaterThan(WeatherStatus.allCases.count, 100)
        XCTAssertTrue(WeatherStatus.allCases.contains(.sunny))
        XCTAssertTrue(WeatherStatus.allCases.contains(.na))
        XCTAssertTrue(WeatherStatus.allCases.contains(.unitTest))
    }

    func testWeatherColorRawValues() {
        XCTAssertEqual(0x1fbfff, WeatherColor.rain.rawValue)
        XCTAssertEqual(0x1f4f74, WeatherColor.defaultColor.rawValue)
        XCTAssertEqual(0x0f2a3f, WeatherColor.nightColor.rawValue)
        XCTAssertEqual(0x65DA7D, WeatherColor.watchRing.rawValue)
    }

    func testWeatherStatusStringRepresentationStable() {
        // The image lookup uses String(describing: status); regressions would break asset lookup.
        XCTAssertEqual("sunny", String(describing: WeatherStatus.sunny))
        XCTAssertEqual("mostlyCloudy", String(describing: WeatherStatus.mostlyCloudy))
        XCTAssertEqual("partlyCloudy", String(describing: WeatherStatus.partlyCloudy))
        XCTAssertEqual("na", String(describing: WeatherStatus.na))
    }
}
