//
//  PreferenceHelperTests.swift
//  weatherlrTests
//
//  These tests rely on APP_GROUP_ID being set in the test bundle Info.plist so
//  that UserDefaults(suiteName: Global.SettingGroup) returns a real, isolated
//  defaults instance.
//

import XCTest
@testable import weatherlr

class PreferenceHelperTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: Global.SettingGroup)
        defaults?.removePersistentDomain(forName: Global.SettingGroup)
    }

    override func tearDown() {
        defaults?.removePersistentDomain(forName: Global.SettingGroup)
        super.tearDown()
    }

    private func city(id: String, en: String = "Test", fr: String = "Test") -> City {
        return City(id: id, frenchName: fr, englishName: en, province: "QC",
                    radarId: "WMN", latitude: "45", longitude: "-73")
    }

    // MARK: - extractLang

    func testExtractLangStripsRegion() {
        XCTAssertEqual("en", PreferenceHelper.extractLang("en-CA"))
        XCTAssertEqual("fr", PreferenceHelper.extractLang("fr-CA"))
        XCTAssertEqual("fr", PreferenceHelper.extractLang("fr-FR"))
    }

    func testExtractLangPassThroughWhenNoDash() {
        XCTAssertEqual("en", PreferenceHelper.extractLang("en"))
        XCTAssertEqual("fr", PreferenceHelper.extractLang("fr"))
        XCTAssertEqual("", PreferenceHelper.extractLang(""))
    }

    // MARK: - saveLanguage / getLanguage

    func testSaveAndGetLanguageFrench() {
        PreferenceHelper.saveLanguage(.French)
        XCTAssertEqual(.French, PreferenceHelper.getLanguage())
        XCTAssertTrue(PreferenceHelper.isFrench())
    }

    func testSaveAndGetLanguageEnglish() {
        PreferenceHelper.saveLanguage(.English)
        XCTAssertEqual(.English, PreferenceHelper.getLanguage())
        XCTAssertFalse(PreferenceHelper.isFrench())
    }

    func testGetLanguageFallsBackWhenUnset() {
        // With a fresh defaults suite, getLanguage() ends up persisting whichever
        // language matches the user's preferred locale (or English).
        let lang = PreferenceHelper.getLanguage()
        XCTAssertTrue(lang == .English || lang == .French)
    }

    // MARK: - saveSelectedCity / getSelectedCity

    func testSaveAndGetSelectedCity() {
        let c = city(id: "qc-147", en: "Montreal", fr: "Montréal")
        PreferenceHelper.saveSelectedCity(c)
        XCTAssertEqual("qc-147", PreferenceHelper.getSelectedCity().id)
    }

    func testGetSelectedCityFallsBackToCurrentLocationWhenUnset() {
        let selected = PreferenceHelper.getSelectedCity()
        XCTAssertEqual(Global.currentLocationCityId, selected.id)
    }

    // MARK: - addFavorite / getFavoriteCities / removeFavorite

    func testAddFavoriteIncludesCurrentLocationFirst() {
        let favorites = PreferenceHelper.getFavoriteCities()
        XCTAssertEqual(Global.currentLocationCityId, favorites.first?.id)
    }

    func testAddFavoriteStoresCityAndSelects() {
        let c = city(id: "qc-147", en: "Montreal")
        PreferenceHelper.addFavorite(c)

        let favorites = PreferenceHelper.getFavoriteCities()
        // Current location is always first, then the new favorite
        XCTAssertGreaterThanOrEqual(favorites.count, 2)
        XCTAssertEqual(Global.currentLocationCityId, favorites[0].id)
        XCTAssertEqual("qc-147", favorites[1].id)

        // Adding a favorite also marks it as the selected city
        XCTAssertEqual("qc-147", PreferenceHelper.getSelectedCity().id)
    }

    func testAddFavoriteDeduplicates() {
        let c = city(id: "qc-147")
        PreferenceHelper.addFavorite(c)
        PreferenceHelper.addFavorite(c)

        let favorites = PreferenceHelper.getFavoriteCities()
        let count = favorites.filter { $0.id == "qc-147" }.count
        XCTAssertEqual(1, count)
    }

    func testAddMultipleFavoritesMostRecentFirst() {
        let m = city(id: "qc-147", en: "Montreal")
        let t = city(id: "on-143", en: "Toronto")
        PreferenceHelper.addFavorite(m)
        PreferenceHelper.addFavorite(t)

        let favorites = PreferenceHelper.getFavoriteCities()
        // Expected order: [currentLocation, Toronto (most recent), Montreal]
        XCTAssertEqual(Global.currentLocationCityId, favorites[0].id)
        XCTAssertEqual("on-143", favorites[1].id)
        XCTAssertEqual("qc-147", favorites[2].id)
    }

    func testRemoveFavorite() {
        let m = city(id: "qc-147")
        let t = city(id: "on-143")
        PreferenceHelper.addFavorite(m)
        PreferenceHelper.addFavorite(t)

        PreferenceHelper.removeFavorite(t)
        let favorites = PreferenceHelper.getFavoriteCities()
        let ids = favorites.map { $0.id }
        XCTAssertFalse(ids.contains("on-143"))
        XCTAssertTrue(ids.contains("qc-147"))
    }

    func testRemoveFavoritesKeepsOnlySelected() {
        let m = city(id: "qc-147")
        let t = city(id: "on-143")
        PreferenceHelper.addFavorite(m)
        PreferenceHelper.addFavorite(t)
        // Selected is now "on-143" (last added)

        PreferenceHelper.removeFavorites()
        let favorites = PreferenceHelper.getFavoriteCities()
        // After removeFavorites(): [currentLocation (auto-inserted), selectedCity (on-143)]
        let ids = favorites.map { $0.id }
        XCTAssertTrue(ids.contains(Global.currentLocationCityId))
        XCTAssertTrue(ids.contains("on-143"))
    }

    // MARK: - saveLastLocatedCity / removeLastLocatedCity / getCityToUse

    func testGetCityToUseReturnsSelectedWhenNotCurrentLocation() {
        let c = city(id: "qc-147")
        PreferenceHelper.saveSelectedCity(c)
        XCTAssertEqual("qc-147", PreferenceHelper.getCityToUse().id)
    }

    func testGetCityToUseReturnsLastLocatedWhenCurrentLocationSelected() {
        // Default selected is current location, no last located → fallback
        let fallback = PreferenceHelper.getCityToUse()
        XCTAssertEqual(Global.currentLocationCityId, fallback.id)

        // Now save a "last located" city and check it comes back
        let located = city(id: "qc-147", en: "Montreal")
        PreferenceHelper.saveLastLocatedCity(located)
        XCTAssertEqual("qc-147", PreferenceHelper.getCityToUse().id)

        // Clear it, back to current location
        PreferenceHelper.removeLastLocatedCity()
        XCTAssertEqual(Global.currentLocationCityId, PreferenceHelper.getCityToUse().id)
    }
}
