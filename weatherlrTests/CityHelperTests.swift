//
//  CityHelperTests.swift
//  weatherlrTests
//

import XCTest
@testable import weatherlr

class CityHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // PreferenceHelperTests may leave the language as French — reset to
        // English so tests that compare city names and sort order are stable.
        PreferenceHelper.saveLanguage(.English)
    }

    private func city(id: String, en: String, fr: String, province: String = "QC") -> City {
        return City(id: id, frenchName: fr, englishName: en, province: province, radarId: "", latitude: "", longitude: "")
    }

    private func sampleList() -> [City] {
        return [
            city(id: "qc-147", en: "Montréal",  fr: "Montréal"),
            city(id: "on-143", en: "Toronto",   fr: "Toronto"),
            city(id: "qc-133", en: "Québec",    fr: "Québec"),
            city(id: "bc-74",  en: "Vancouver", fr: "Vancouver"),
        ]
    }

    // MARK: - searchCity

    func testSearchCityCaseInsensitiveAndDiacriticFolded() {
        let list = sampleList()
        // Lowercase, no diacritics → should still match "Québec" / "Montréal"
        let result = CityHelper.searchCity("quebec", allCityList: list)
        XCTAssertEqual(1, result.count)
        XCTAssertEqual("qc-133", result.first?.id)
    }

    func testSearchCityPartialMatch() {
        let list = sampleList()
        let result = CityHelper.searchCity("van", allCityList: list)
        XCTAssertEqual(1, result.count)
        XCTAssertEqual("bc-74", result.first?.id)
    }

    func testSearchCityNoMatch() {
        let list = sampleList()
        let result = CityHelper.searchCity("ZZZ", allCityList: list)
        XCTAssertEqual(0, result.count)
    }

    func testSearchCityEmptyStringMatchesNothing() {
        // Swift's String.contains("") returns false, so an empty query finds
        // nothing. Pin the behavior so a future change is a deliberate choice.
        let list = sampleList()
        let result = CityHelper.searchCity("", allCityList: list)
        XCTAssertEqual(0, result.count)
    }

    // MARK: - searchCityStartingWith

    func testSearchCityStartingWithMatchesPrefix() {
        let list = sampleList()
        let result = CityHelper.searchCityStartingWith("TOR", allCityList: list)
        XCTAssertEqual(1, result.count)
        XCTAssertEqual("on-143", result.first?.id)
    }

    func testSearchCityStartingWithNoMatch() {
        let list = sampleList()
        let result = CityHelper.searchCityStartingWith("XYZ", allCityList: list)
        XCTAssertEqual(0, result.count)
    }

    // MARK: - searchSingleCity

    func testSearchSingleCityReturnsFirstMatch() {
        let list = sampleList()
        let result = CityHelper.searchSingleCity("mont", allCityList: list)
        XCTAssertNotNil(result)
        XCTAssertEqual("qc-147", result?.id)
    }

    func testSearchSingleCityReturnsNilWhenMissing() {
        XCTAssertNil(CityHelper.searchSingleCity("XXX", allCityList: sampleList()))
    }

    // MARK: - sortCityList

    func testSortCityListOrdersByEnglishNameWhenEnglish() {
        // getLanguage() defaults to English on a fresh test bundle
        let sorted = CityHelper.sortCityList(sampleList())
        let ids = sorted.map { $0.id }
        // Alphabetical English: Montréal, Québec, Toronto, Vancouver
        XCTAssertEqual(["qc-147", "qc-133", "on-143", "bc-74"], ids)
    }

    func testSortCityListHandlesEmpty() {
        let sorted = CityHelper.sortCityList([])
        XCTAssertEqual(0, sorted.count)
    }

    // MARK: - cityName / cityNameForSearch

    func testCityNameReturnsEnglishByDefault() {
        let c = city(id: "x", en: "Hello", fr: "Bonjour")
        XCTAssertEqual("Hello", CityHelper.cityName(c))
    }

    func testCityNameForSearchFoldsDiacritics() {
        let c = city(id: "x", en: "Montréal", fr: "Montréal")
        let name = CityHelper.cityNameForSearch(c)
        XCTAssertEqual("MONTREAL", name)
    }

    // MARK: - getCurrentLocationCity

    func testGetCurrentLocationCityHasSentinelId() {
        let c = CityHelper.getCurrentLocationCity()
        XCTAssertEqual(Global.currentLocationCityId, c.id)
        XCTAssertFalse(c.englishName.isEmpty)
        XCTAssertFalse(c.frenchName.isEmpty)
    }

    // MARK: - City Codable round-trip

    func testCityCodableRoundTrip() throws {
        let original = City(id: "qc-147", frenchName: "Montréal", englishName: "Montreal",
                            province: "QC", radarId: "WMN", latitude: "45.5", longitude: "-73.5")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(City.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testCityEquatableAndHashable() {
        let a = city(id: "1", en: "A", fr: "A")
        let b = city(id: "1", en: "A", fr: "A")
        let c = city(id: "2", en: "A", fr: "A")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        let set: Set<City> = [a, b, c]
        XCTAssertEqual(2, set.count)
    }

    // MARK: - LegacyCity migration

    func testLegacyCityToCityCopiesAllFields() {
        let legacy = LegacyCity()
        legacy.id = "qc-147"
        legacy.frenchName = "Montréal"
        legacy.englishName = "Montreal"
        legacy.province = "QC"
        legacy.radarId = "WMN"
        legacy.latitude = "45.5"
        legacy.longitude = "-73.5"

        let c = legacy.toCity()
        XCTAssertEqual("qc-147", c.id)
        XCTAssertEqual("Montréal", c.frenchName)
        XCTAssertEqual("Montreal", c.englishName)
        XCTAssertEqual("QC", c.province)
        XCTAssertEqual("WMN", c.radarId)
        XCTAssertEqual("45.5", c.latitude)
        XCTAssertEqual("-73.5", c.longitude)
    }

    func testLegacyCityNSCodingRoundTrip() throws {
        let legacy = LegacyCity()
        legacy.id = "on-143"
        legacy.englishName = "Toronto"
        legacy.frenchName = "Toronto"
        legacy.province = "ON"
        legacy.radarId = "WKR"
        legacy.latitude = "43.65"
        legacy.longitude = "-79.38"

        let data = try NSKeyedArchiver.archivedData(withRootObject: legacy, requiringSecureCoding: false)
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        let decoded = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? LegacyCity
        XCTAssertNotNil(decoded)
        XCTAssertEqual("on-143", decoded?.id)
        XCTAssertEqual("Toronto", decoded?.englishName)
        XCTAssertEqual("WKR", decoded?.radarId)
    }
}
