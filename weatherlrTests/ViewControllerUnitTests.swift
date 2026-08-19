//
//  ViewControllerUnitTests.swift
//  weatherlrTests
//
//  Unit tests that instantiate storyboard-backed view controllers directly
//  and force their view hierarchy to load. This covers simple VCs whose
//  viewDidLoad + outlet wiring is pure enough to test without XCUI.
//
//  View controllers covered here are ones that:
//    * Don't require network or location
//    * Either build their UI entirely in code, or rely only on storyboard outlets
//    * Are hard to reach through normal UI navigation (popovers, error screens)
//

import XCTest
import UIKit
@testable import weatherlr

@MainActor
class ViewControllerUnitTests: XCTestCase {

    private var storyboard: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: Bundle(for: AppDelegate.self))
    }

    // Convenience: force-load the view hierarchy so viewDidLoad fires.
    private func loadView(_ vc: UIViewController) {
        vc.loadViewIfNeeded()
        // Lay out the view so constraints + subview setup code paths run.
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()
    }

    // MARK: - AlertViewController

    func testAlertViewControllerLoadsWithOneAlert() throws {
        let alert = AlertInformation(alertText: "Severe thunderstorm warning in effect",
                                     url: "https://example.com",
                                     type: .warning)
        let vc = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "Alert") as? AlertViewController
        )
        vc.alerts = [alert]
        loadView(vc)

        XCTAssertEqual("Severe thunderstorm warning in effect", vc.alertLabel.text)
        XCTAssertEqual("alertLabel", vc.alertLabel.accessibilityIdentifier)
        XCTAssertNotNil(vc.moreDetailButton)
        XCTAssertEqual("moreDetailsButton", vc.moreDetailButton.accessibilityIdentifier)
    }

    func testAlertViewControllerLoadsWithMultipleAlerts() throws {
        let alerts = [
            AlertInformation(alertText: "tornado warning", url: "", type: .warning),
            AlertInformation(alertText: "flood advisory", url: "", type: .warning),
        ]
        let vc = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "Alert") as? AlertViewController
        )
        vc.alerts = alerts
        loadView(vc)

        // Multi-alert concatenation inserts a newline between entries.
        XCTAssertTrue(vc.alertLabel.text?.contains("\n") ?? false)
        // First char of each line is capitalized by getTextCapitalized.
        XCTAssertTrue(vc.alertLabel.text?.hasPrefix("Tornado") ?? false)
    }

    func testAlertViewControllerGetTextCapitalized() throws {
        let vc = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "Alert") as? AlertViewController
        )
        XCTAssertEqual("Hello world", vc.getTextCapitalized("hello world"))
        XCTAssertEqual("Éclairs", vc.getTextCapitalized("ÉCLAIRS".lowercased()))
    }

    // MARK: - AlertDetailViewController

    func testAlertDetailViewControllerLoadsWithOneAlert() {
        // AlertDetailViewController builds its UI in code, so instantiating
        // it directly is enough — no storyboard identifier needed.
        let vc = AlertDetailViewController()
        vc.alerts = [
            AlertInformation(alertText: "severe weather",
                             url: "https://example.com",
                             type: .warning,
                             eventIssueTime: "2026-04-11T12:00:00Z",
                             expiryTime: "2026-04-11T20:00:00Z",
                             alertColourLevel: "red")
        ]
        let nav = UINavigationController(rootViewController: vc)
        _ = nav.view
        vc.loadViewIfNeeded()
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()

        XCTAssertNotNil(vc.view)
        XCTAssertFalse(vc.view.subviews.isEmpty)
        // Title set in viewDidLoad
        XCTAssertFalse((vc.title ?? "").isEmpty)
    }

    func testAlertDetailViewControllerRendersBody() {
        let vc = AlertDetailViewController()
        vc.alerts = [
            AlertInformation(alertText: "severe weather",
                             url: "https://example.com",
                             type: .warning,
                             eventIssueTime: "2026-04-11T12:00:00Z",
                             expiryTime: "2026-04-11T20:00:00Z",
                             alertColourLevel: "red",
                             alertDetails: "Damaging winds expected. Secure loose objects.")
        ]
        let nav = UINavigationController(rootViewController: vc)
        _ = nav.view
        vc.loadViewIfNeeded()
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()

        let labels = allLabels(in: vc.view)
        XCTAssertTrue(labels.contains { $0.text == "Damaging winds expected. Secure loose objects." },
                      "The full warning body should be rendered as a label")
    }

    /// Recursively collects every UILabel in a view hierarchy.
    private func allLabels(in view: UIView) -> [UILabel] {
        var result = [UILabel]()
        for subview in view.subviews {
            if let label = subview as? UILabel {
                result.append(label)
            }
            result.append(contentsOf: allLabels(in: subview))
        }
        return result
    }

    func testAlertDetailViewControllerLoadsWithMultipleAlerts() {
        let vc = AlertDetailViewController()
        vc.alerts = [
            AlertInformation(alertText: "first", url: "", type: .warning),
            AlertInformation(alertText: "second", url: "", type: .warning),
            AlertInformation(alertText: "third", url: "", type: .warning),
        ]
        let nav = UINavigationController(rootViewController: vc)
        _ = nav.view
        vc.loadViewIfNeeded()
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()

        XCTAssertNotNil(vc.view)
    }

    func testAlertDetailViewControllerEmptyAlerts() {
        let vc = AlertDetailViewController()
        vc.alerts = []
        _ = UINavigationController(rootViewController: vc)
        vc.loadViewIfNeeded()
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()

        XCTAssertNotNil(vc.view)
    }

    // MARK: - ErrorViewController

    func testErrorViewControllerLoads() throws {
        let vc = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "error") as? ErrorViewController
        )
        loadView(vc)
        XCTAssertNotNil(vc.view)
        XCTAssertFalse((vc.errorLabel.text ?? "").isEmpty)
    }

    // MARK: - WeatherViewController.displayedCity (#32)

    /// These tests write to the shared app-group defaults; restore them so the
    /// rest of the suite isn't affected by the city we select here.
    private func restoreDefaultsAfterTest() {
        addTeardownBlock {
            UserDefaults(suiteName: Global.SettingGroup)?
                .removePersistentDomain(forName: Global.SettingGroup)
        }
    }

    private func testCity(id: String, en: String) -> City {
        return City(id: id, frenchName: en, englishName: en, province: "QC",
                    radarId: "WMN", latitude: "45", longitude: "-73")
    }

    /// Before any fetch has landed there is no wrapper city, so the header has
    /// nothing to follow but the selection.
    func testDisplayedCityFallsBackToSelectionWhenNoWrapperCity() {
        restoreDefaultsAfterTest()
        let montreal = testCity(id: "s0000635", en: "Montreal")
        PreferenceHelper.saveSelectedCity(montreal)

        let vc = WeatherViewController()
        XCTAssertEqual(montreal.id, vc.displayedCity.id)
    }

    /// The header must name the city the on-screen data was fetched for, not the
    /// newly selected one — otherwise header and body desync while the fetch for
    /// the new city is still in flight.
    func testDisplayedCityFollowsWrapperCityNotSelection() {
        restoreDefaultsAfterTest()
        let granby = testCity(id: "s0000255", en: "Granby")
        let montreal = testCity(id: "s0000635", en: "Montreal")

        let vc = WeatherViewController()
        vc.weatherInformationWrapper = WeatherInformationWrapper(weatherInformations: [],
                                                                 alerts: [],
                                                                 hourlyForecasts: [],
                                                                 city: granby)
        PreferenceHelper.saveSelectedCity(montreal)

        XCTAssertEqual(granby.id, vc.displayedCity.id)
    }

    /// While locating, the placeholder city drives the "Locating" header state
    /// and must not be overridden by a stale wrapper.
    func testDisplayedCityKeepsLocatingPlaceholder() {
        restoreDefaultsAfterTest()
        let defaults = UserDefaults(suiteName: Global.SettingGroup)
        defaults?.removeObject(forKey: Global.lastLocatedCityKey)
        PreferenceHelper.saveSelectedCity(CityHelper.getCurrentLocationCity())

        let vc = WeatherViewController()
        vc.weatherInformationWrapper = WeatherInformationWrapper(weatherInformations: [],
                                                                 alerts: [],
                                                                 hourlyForecasts: [],
                                                                 city: testCity(id: "s0000255", en: "Granby"))

        XCTAssertTrue(LocationServices.isUseCurrentLocation(vc.displayedCity))
    }
}
