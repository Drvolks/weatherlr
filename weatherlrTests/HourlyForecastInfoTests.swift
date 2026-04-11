//
//  HourlyForecastInfoTests.swift
//  weatherlrTests
//

import XCTest
@testable import weatherlr

class HourlyForecastInfoTests: XCTestCase {

    private func date(hour: Int) -> Date {
        // Build a specific local-calendar date at `hour:00:00` so the
        // `night` fallback (which uses `Calendar.current.component(.hour:)`)
        // has a deterministic value.
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 4
        comps.day = 11
        comps.hour = hour
        comps.minute = 0
        return Calendar.current.date(from: comps)!
    }

    func testFieldsStored() {
        let info = HourlyForecastInfo(date: date(hour: 12), temperature: 15, iconCode: 2, precipChance: 30)
        XCTAssertEqual(15, info.temperature)
        XCTAssertEqual(2, info.iconCode)
        XCTAssertEqual(30, info.precipChance)
    }

    func testNightFromIconCodeRange() {
        let night = HourlyForecastInfo(date: date(hour: 12), temperature: 10, iconCode: 31, precipChance: 0)
        let day = HourlyForecastInfo(date: date(hour: 12), temperature: 10, iconCode: 2, precipChance: 0)
        XCTAssertTrue(night.night)  // iconCode 30-39 → night
        XCTAssertFalse(day.night)
    }

    func testNightBoundaryIconCodes() {
        XCTAssertTrue(HourlyForecastInfo(date: date(hour: 12), temperature: 0, iconCode: 30, precipChance: 0).night)
        XCTAssertTrue(HourlyForecastInfo(date: date(hour: 12), temperature: 0, iconCode: 39, precipChance: 0).night)
        XCTAssertFalse(HourlyForecastInfo(date: date(hour: 12), temperature: 0, iconCode: 29, precipChance: 0).night)
        XCTAssertFalse(HourlyForecastInfo(date: date(hour: 12), temperature: 0, iconCode: 40, precipChance: 0).night)
    }

    func testNightFallbackToHourWhenIconMissing() {
        let morning = HourlyForecastInfo(date: date(hour: 8), temperature: 10, iconCode: nil, precipChance: 0)
        let evening = HourlyForecastInfo(date: date(hour: 20), temperature: 10, iconCode: nil, precipChance: 0)
        let midnight = HourlyForecastInfo(date: date(hour: 2), temperature: 10, iconCode: nil, precipChance: 0)
        let boundary = HourlyForecastInfo(date: date(hour: 19), temperature: 10, iconCode: nil, precipChance: 0)

        XCTAssertFalse(morning.night)   // 8 → day
        XCTAssertTrue(evening.night)    // 20 → night
        XCTAssertTrue(midnight.night)   // 2 → night
        XCTAssertTrue(boundary.night)   // 19 → night (>= 19)
    }

    func testImageNameFromIconCode() {
        let info = HourlyForecastInfo(date: date(hour: 12), temperature: 10, iconCode: 0, precipChance: 0)
        XCTAssertEqual("sunny", info.imageName)
    }

    func testImageNameFallbackToNaWhenMissingOrUnknown() {
        let missing = HourlyForecastInfo(date: date(hour: 12), temperature: 10, iconCode: nil, precipChance: 0)
        XCTAssertEqual("na", missing.imageName)

        let unknown = HourlyForecastInfo(date: date(hour: 12), temperature: 10, iconCode: 999, precipChance: 0)
        XCTAssertEqual("na", unknown.imageName)
    }
}
