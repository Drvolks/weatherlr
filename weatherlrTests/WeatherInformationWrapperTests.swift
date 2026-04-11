//
//  WeatherInformationWrapperTests.swift
//  weatherlrTests
//

import XCTest
@testable import weatherlr

class WeatherInformationWrapperTests: XCTestCase {

    private func makeCity(id: String = "qc-147") -> City {
        return City(id: id, frenchName: "Test", englishName: "Test",
                    province: "QC", radarId: "", latitude: "", longitude: "")
    }

    private func makeWeatherInfo() -> WeatherInformation {
        return WeatherInformation(temperature: 10, weatherStatus: .sunny, weatherDay: .today,
                                  summary: "s", detail: "d", tendancy: .maximum, when: "",
                                  night: false, dateObservation: "")
    }

    func testBaseInitializerIsInitialState() {
        let w = WeatherInformationWrapper()
        XCTAssertTrue(w.initialState)
        XCTAssertEqual(0, w.weatherInformations.count)
        XCTAssertEqual(0, w.alerts.count)
        XCTAssertEqual(0, w.hourlyForecasts.count)
        XCTAssertNil(w.city)
        XCTAssertTrue(w.refreshNeeded()) // initialState → refresh needed
    }

    func testInitializerWithDataIsNotInitialState() {
        let city = makeCity()
        let w = WeatherInformationWrapper(weatherInformations: [makeWeatherInfo()],
                                          alerts: [],
                                          hourlyForecasts: [],
                                          city: city)
        XCTAssertFalse(w.initialState)
        XCTAssertEqual(1, w.weatherInformations.count)
        XCTAssertEqual(city.id, w.city?.id)
    }

    func testExpiredReturnsFalseWhenFresh() {
        let w = WeatherInformationWrapper(weatherInformations: [makeWeatherInfo()],
                                          alerts: [],
                                          hourlyForecasts: [],
                                          city: makeCity())
        // lastRefresh = now → not expired
        XCTAssertFalse(w.expired())
        XCTAssertFalse(w.expiredTooLongAgo())
    }

    func testExpiredReturnsTrueWhenStale() {
        let w = WeatherInformationWrapper(weatherInformations: [makeWeatherInfo()],
                                          alerts: [],
                                          hourlyForecasts: [],
                                          city: makeCity())
        // Force stale: set lastRefresh to (Global.expirationInMinutes + 5) minutes ago
        let staleAgo = TimeInterval(-(Global.expirationInMinutes + 5) * 60)
        w.lastRefresh = Date().addingTimeInterval(staleAgo)
        XCTAssertTrue(w.expired())
    }

    func testExpiredTooLongAgo() {
        let w = WeatherInformationWrapper(weatherInformations: [makeWeatherInfo()],
                                          alerts: [],
                                          hourlyForecasts: [],
                                          city: makeCity())
        // 4x expiration ago
        let wayStale = TimeInterval(-Global.expirationInMinutes * 60 * 4)
        w.lastRefresh = Date().addingTimeInterval(wayStale)
        XCTAssertTrue(w.expired())
        XCTAssertTrue(w.expiredTooLongAgo())
    }

    func testRefreshNeededWhenWeatherListEmpty() {
        let w = WeatherInformationWrapper(weatherInformations: [],
                                          alerts: [],
                                          hourlyForecasts: [],
                                          city: makeCity())
        XCTAssertTrue(w.refreshNeeded())
    }
}
