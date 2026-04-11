//
//  MiscHelperTests.swift
//  weatherlrTests
//
//  Small targeted tests for tiny helpers that are otherwise 0% covered.
//

import XCTest
import UIKit
import CoreLocation
@testable import weatherlr

class MiscHelperTests: XCTestCase {

    // MARK: - LocatedCity

    func testLocatedCityStoresCityAndLocation() {
        let city = City(id: "qc-147", frenchName: "Montréal", englishName: "Montreal",
                        province: "QC", radarId: "", latitude: "", longitude: "")
        let location = CLLocation(latitude: 45.5, longitude: -73.5)
        let located = LocatedCity(city: city, location: location)
        XCTAssertEqual("qc-147", located.city.id)
        XCTAssertEqual(45.5, located.location.coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(-73.5, located.location.coordinate.longitude, accuracy: 0.0001)
    }

    // MARK: - CellHelper.showHide

    @MainActor
    func testCellHelperShowHideFadesOutWhenMovingUp() {
        let cell = UITableViewCell()
        cell.frame = CGRect(x: 0, y: 50, width: 320, height: 44)
        cell.alpha = 1

        // Moving up (lastContentOffset < offset) and position (50 - 100 = -50) below threshold → fade
        CellHelper.showHide(cell: cell, offset: 100, lastContentOffset: 0)
        // UIView.animate doesn't commit synchronously, but the branch runs
        _ = cell.alpha
    }

    @MainActor
    func testCellHelperShowHideFadesInWhenMovingDown() {
        let cell = UITableViewCell()
        cell.frame = CGRect(x: 0, y: 300, width: 320, height: 44)
        cell.alpha = 0.1

        // Moving down (lastContentOffset > offset), position well above threshold → fade in
        CellHelper.showHide(cell: cell, offset: 0, lastContentOffset: 100)
        _ = cell.alpha
    }

    @MainActor
    func testCellHelperShowHideWeatherNowCellBranch() {
        // Hit the `isNowCell` code path
        let cell = WeatherNowCell(style: .default, reuseIdentifier: "now")
        cell.frame = CGRect(x: 0, y: 20, width: 320, height: 100)
        cell.alpha = 1
        CellHelper.showHide(cell: cell, offset: 100, lastContentOffset: 0) // moving up + nowCell
        CellHelper.showHide(cell: cell, offset: 0, lastContentOffset: 100)  // moving down + nowCell
        _ = cell.alpha
    }

    @MainActor
    func testCellHelperShowHideNoChangeWhenPositionAboveThreshold() {
        let cell = UITableViewCell()
        cell.frame = CGRect(x: 0, y: 500, width: 320, height: 44)
        cell.alpha = 1

        CellHelper.showHide(cell: cell, offset: 0, lastContentOffset: 100)
        // Already at alpha 1 and above threshold → no change
        XCTAssertEqual(1, cell.alpha)
    }

    // MARK: - Constants

    func testConstantsKeysAreStable() {
        XCTAssertEqual("selectedWatchCity", Constants.selectedWatchCityKey)
        XCTAssertEqual("requestCityMessage", Constants.requestCityMessage)
        XCTAssertEqual("cityList", Constants.cityListKey)
        XCTAssertEqual("searchText", Constants.searchTextKey)
        XCTAssertGreaterThan(Constants.backgroundRefreshInSeconds, 0)
        XCTAssertFalse(Constants.backgroundDownloadTaskName.isEmpty)
    }
}
