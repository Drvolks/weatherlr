//
//  PWSServiceTests.swift
//  weatherlrTests
//
//  Covers issue #15: the PWS station-name lookup must return a configured
//  station's name regardless of its distance from the selected city, so the
//  watchOS header can name the station behind a substituted PWS temperature.
//
//  These tests rely on APP_GROUP_ID being set in the test bundle Info.plist so
//  that UserDefaults(suiteName: Global.SettingGroup) returns a real, isolated
//  defaults instance.
//

#if ENABLE_PWS
import XCTest
@testable import weatherlr

@MainActor
final class PWSServiceTests: XCTestCase {

    nonisolated private func resetDefaults() {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        defaults.removePersistentDomain(forName: Global.SettingGroup)
        // hasPWSCredentials() needs a non-empty API key (synced-key fallback used when
        // no Secrets.plist key is present).
        defaults.set("test-api-key", forKey: "pwsApiKey")
    }

    override func setUp() {
        super.setUp()
        resetDefaults()
    }

    override func tearDown() {
        UserDefaults(suiteName: Global.SettingGroup)!.removePersistentDomain(forName: Global.SettingGroup)
        super.tearDown()
    }

    private func montreal() -> City {
        return City(id: "1", frenchName: "Montréal", englishName: "Montreal",
                    province: "QC", radarId: "WMN", latitude: "45.5", longitude: "-73.6")
    }

    func testClosestStationNameReturnsNilWhenNoStations() {
        PreferenceHelper.savePWSStations([])
        XCTAssertNil(PWSService.shared.closestStationName(to: montreal()))
    }

    func testClosestStationNameReturnsNearestStation() {
        PreferenceHelper.savePWSStations([
            PWSStation(stationId: "S1", name: "Near", latitude: 45.51, longitude: -73.61),
            PWSStation(stationId: "S2", name: "Far", latitude: 46.8, longitude: -71.2)
        ])
        XCTAssertEqual("Near", PWSService.shared.closestStationName(to: montreal()))
    }

    func testClosestStationNameReturnsStationBeyond50km() {
        // The only configured station is well beyond the old 50 km cap (Montreal -> Quebec
        // City is ~230 km). The user explicitly configured it, so its name must still surface.
        PreferenceHelper.savePWSStations([
            PWSStation(stationId: "S2", name: "Quebec City", latitude: 46.81, longitude: -71.21)
        ])
        XCTAssertEqual("Quebec City", PWSService.shared.closestStationName(to: montreal()))
    }
}
#endif
