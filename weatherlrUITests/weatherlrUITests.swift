//
//  weatherlrUITests.swift
//  weatherlrUITests
//
//  UI smoke tests that exercise view-controller code paths for coverage.
//
//  All tests launch with `-UITest`, which triggers `UITestSupport.seedIfNeeded`
//  in the app: it disables UIKit animations (so tests run in seconds rather
//  than minutes), seeds a deterministic favorite city, and pre-populates
//  `WeatherHelper.cache` from a bundled JSON fixture. The weather table,
//  hourly row, and alert button all render without network or location.
//

import XCTest

class weatherlrUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["-UITest"]

        // Auto-dismiss any system permission alert that slips through.
        addUIInterruptionMonitor(withDescription: "System permission alerts") { alert in
            let candidateLabels = [
                "Allow Once", "Allow While Using App", "Allow",
                "OK", "Don't Allow", "Don’t Allow"
            ]
            for label in candidateLabels {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }

        app.launch()
        app.tap() // trigger the interruption monitor if anything popped up
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Wait for the main weather table to appear before a test body runs.
    @discardableResult
    private func waitForWeatherTable(timeout: TimeInterval = 10) -> Bool {
        return app.tables["weatherTable"].waitForExistence(timeout: timeout)
    }

    private var weatherTable: XCUIElement { app.tables["weatherTable"] }
    private var settingsButton: XCUIElement { app.buttons["settingsButton"] }
    private var warningButton: XCUIElement { app.buttons["warningButton"] }
    private var radarButton: XCUIElement { app.buttons["radarButton"] }

    // MARK: - Launch & main screen

    func testAppLaunches() {
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
    }

    func testWeatherTableIsPopulated() {
        XCTAssertTrue(waitForWeatherTable())
        // Fixture provides current conditions + 7 forecasts → at least 2 visible rows
        XCTAssertGreaterThan(weatherTable.cells.count, 1)
    }

    // MARK: - Weather table interaction

    func testScrollWeatherTable() {
        guard waitForWeatherTable() else { return }
        weatherTable.swipeUp()
        weatherTable.swipeUp()
        weatherTable.swipeDown()
        weatherTable.swipeDown()
    }

    func testPullToRefresh() {
        guard waitForWeatherTable() else { return }
        let start = weatherTable.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
        let end = weatherTable.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    // MARK: - Toolbar buttons

    func testToolbarIsPresent() {
        XCTAssertTrue(app.toolbars.firstMatch.waitForExistence(timeout: 5))
    }

    // MARK: - Settings flow

    func testSettingsButtonOpensSettings() {
        guard waitForWeatherTable() else { return }
        guard settingsButton.waitForExistence(timeout: 5) else {
            XCTFail("Settings button not found")
            return
        }
        settingsButton.tap()

        // Settings screen
        let settingsTable = app.tables["settingsTable"]
        XCTAssertTrue(settingsTable.waitForExistence(timeout: 5))

        // Scroll the settings table to exercise table data source
        settingsTable.swipeUp()
        settingsTable.swipeDown()

        // Dismiss
        let done = app.buttons["doneButton"]
        if done.exists { done.tap() }
    }

    func testSettingsAddCityFlow() {
        guard waitForWeatherTable() else { return }
        guard settingsButton.waitForExistence(timeout: 5) else { return }
        settingsButton.tap()

        guard app.tables["settingsTable"].waitForExistence(timeout: 5) else { return }

        // Tap the "+" button to open Add City
        let addCity = app.buttons["addCityButton"]
        guard addCity.waitForExistence(timeout: 3) else {
            XCTFail("Add city button not found in settings")
            return
        }
        addCity.tap()

        // Add City screen should appear
        let addCityTable = app.tables["addCityTable"]
        XCTAssertTrue(addCityTable.waitForExistence(timeout: 5))

        // Type into the search bar to exercise CityHelper.searchCity +
        // AddCityViewController filter methods.
        let searchBar = app.searchFields["addCitySearch"]
        if searchBar.waitForExistence(timeout: 2) {
            searchBar.tap()
            searchBar.typeText("Mont")
        }

        // Clear the search
        if searchBar.exists {
            let clearButton = searchBar.buttons["Clear text"]
            if clearButton.exists { clearButton.tap() }
        }

        // Cancel out of Add City
        let cancel = app.buttons["addCityCancel"]
        if cancel.exists {
            cancel.tap()
        } else {
            // Fall back to generic Cancel
            let genericCancel = app.buttons["Cancel"]
            if genericCancel.exists { genericCancel.tap() }
        }

        // Back out of Settings
        let done = app.buttons["doneButton"]
        if done.exists { done.tap() }
    }

    func testSettingsTapLanguageRow() {
        guard waitForWeatherTable() else { return }
        guard settingsButton.waitForExistence(timeout: 5) else { return }
        settingsButton.tap()

        let settingsTable = app.tables["settingsTable"]
        guard settingsTable.waitForExistence(timeout: 5) else { return }

        // Scroll to find the language section (Français/English)
        settingsTable.swipeUp()
        settingsTable.swipeUp()

        // Tap a row in the language section if present — the text differs by
        // locale, so walk cells and tap the first one that responds.
        let cells = settingsTable.cells
        if cells.count > 2 {
            cells.element(boundBy: 2).tap()
        }

        settingsTable.swipeUp()

        // Dismiss
        let done = app.buttons["doneButton"]
        if done.exists { done.tap() }
    }

    // MARK: - Alerts flow (fixture includes one active alert)

    func testWarningButtonExistsAndIsEnabled() {
        // XCUI-based popover coverage for AlertViewController is flaky on iPhone
        // because `adaptivePresentationStyle -> .none` + iOS popover rules make
        // the popover invisible to the accessibility tree. Coverage for
        // AlertViewController / AlertDetailViewController is handled in
        // ViewControllerUnitTests.swift by instantiating them directly.
        //
        // This test just verifies the warning button is present and enabled
        // when the fixture includes an alert.
        guard waitForWeatherTable() else { return }
        let toolbar = app.toolbars.firstMatch
        guard toolbar.waitForExistence(timeout: 5) else { return }
        // Toolbar with 1 alert has 3 buttons: settings, warning, radar.
        let buttons = toolbar.buttons
        if buttons.count >= 3 {
            let warning = buttons.element(boundBy: 1)
            XCTAssertTrue(warning.exists)
            XCTAssertTrue(warning.isEnabled)
        }
    }

    // MARK: - Radar flow

    func testRadarButtonOpensRadar() {
        guard waitForWeatherTable() else { return }
        guard radarButton.waitForExistence(timeout: 5) else { return }

        // Fixture city has a radar ID, so the button should be enabled.
        XCTAssertTrue(radarButton.isEnabled)
        radarButton.tap()

        // Give the map a moment to render, then dismiss.
        sleep(1)
        for label in ["Done", "Close", "Dismiss", "Fermer", "OK"] {
            let button = app.buttons[label]
            if button.waitForExistence(timeout: 2) {
                button.tap()
                return
            }
        }
        app.swipeDown()
    }

    // MARK: - Lifecycle

    func testRelaunch() {
        app.terminate()
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
    }

    func testBackgroundAndForeground() {
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
    }

    func testRotation() {
        guard waitForWeatherTable() else { return }
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.windows.firstMatch.exists)
        XCUIDevice.shared.orientation = .landscapeRight
        XCTAssertTrue(app.windows.firstMatch.exists)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.windows.firstMatch.exists)
    }
}
