//
//  UITestSupport.swift
//  weatherlr
//
//  Launch-time hook that, when the app is started with `-UITest` in the
//  process arguments, seeds UserDefaults with a deterministic city and
//  pre-populates WeatherHelper's cache from a bundled JSON fixture.
//
//  This lets UI tests walk through the main screen, hourly details, radar,
//  settings, and alerts without ever touching the network or CoreLocation.
//

import Foundation
import UIKit

class UITestSupport {

    static let launchArgument = "-UITest"

    /// Returns true if the current process was launched with `-UITest`.
    static var isActive: Bool {
        return ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// Seeds preferences + cache if `-UITest` is present in the launch args.
    /// Safe to call unconditionally from AppDelegate.
    static func seedIfNeeded() {
        guard isActive else { return }

        // 0. Disable UIKit animations — XCUITest otherwise waits up to 60s
        //    for "animations complete" on every tap, making UI tests unusably
        //    slow. With animations off, each interaction completes immediately.
        UIView.setAnimationsEnabled(false)

        // 1. Clear any leftover state in the defaults suite
        if let defaults = UserDefaults(suiteName: Global.SettingGroup) {
            defaults.removePersistentDomain(forName: Global.SettingGroup)
        }

        // 2. Pin the language to English so UI-test assertions are stable
        PreferenceHelper.saveLanguage(.English)

        // 3. Seed a fixture city and make it the selected + favorite
        let city = fixtureCity()
        PreferenceHelper.addFavorite(city)
        PreferenceHelper.saveSelectedCity(city)
        PreferenceHelper.saveLastLocatedCity(city)

        // 4. Pre-populate the weather cache from the bundled JSON fixture so
        //    the main screen renders immediately without hitting the network.
        if let wrapper = loadFixtureWrapper(for: city) {
            WeatherHelper.cache.setObject(wrapper, forKey: city.id, timeout: 3600)
        }
    }

    private static func fixtureCity() -> City {
        return City(
            id: "qc-147",
            frenchName: "Montréal",
            englishName: "Montreal",
            province: "QC",
            radarId: "WMN",
            latitude: "45.5088",
            longitude: "-73.5878"
        )
    }

    private static func loadFixtureWrapper(for city: City) -> WeatherInformationWrapper? {
        guard let url = Bundle.main.url(forResource: "ui_test_fixture", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        let parser = JsonWeatherParser(data: data, language: .English)
        let (weather, alerts, hourly) = parser.parse()
        guard !weather.isEmpty else { return nil }

        return WeatherInformationWrapper(
            weatherInformations: weather,
            alerts: alerts,
            hourlyForecasts: hourly,
            city: city
        )
    }
}
