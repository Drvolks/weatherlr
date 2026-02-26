//
//  WatchWeatherModel.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2026-02-24.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit
import WidgetKit
import CoreLocation
#if ENABLE_WEATHERKIT
import WeatherKit
#endif

@Observable
@MainActor
final class WatchWeatherModel {
    static let shared = WatchWeatherModel()

    var wrapper = WeatherInformationWrapper()
    var isLocating = false
    var locationError: String?
    var updatedDate = Date(timeIntervalSince1970: 0)

    #if ENABLE_PWS
    var pwsTemperature: Int?
    var pwsStationName: String?
    #endif

    #if ENABLE_WEATHERKIT
    var weatherKitData: WeatherKitData?
    #endif

    var locationCoordinator: LocationCoordinator?

    private init() {}

    // MARK: - Ported from ExtensionDelegateHelper

    func refreshNeeded() -> Bool {
        return wrapper.refreshNeeded()
    }

    func resetWeather() {
        wrapper = WeatherInformationWrapper()
        updatedDate = Date(timeIntervalSince1970: 0)
        #if ENABLE_PWS
        pwsTemperature = nil
        pwsStationName = nil
        #endif
        #if ENABLE_WEATHERKIT
        weatherKitData = nil
        #endif
    }

    func updateComplication() {
        #if DEBUG
            print("updateComplication")
        #endif
        WidgetCenter.shared.reloadAllTimelines()
    }

    func scheduleRefresh(_ backgroundRefreshInSeconds: Double) {
        #if DEBUG
            print("scheduleRefresh")
        #endif
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: backgroundRefreshInSeconds), userInfo: nil) { (error: Error?) in
            if let error = error {
                print("Error occured while calling scheduleBackgroundRefresh: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Data loading (ported from InterfaceController)

    func loadData(showError: Bool) {
        let city = PreferenceHelper.getCityToUse()

        if showError {
            // locationError already set by caller
        } else {
            locationError = nil
        }

        if LocationServices.isUseCurrentLocation(city) {
            if !showError {
                isLocating = true
            }

            locationCoordinator?.locationServices?.start()
            locationCoordinator?.locationServices?.updateCity(city)

            if refreshNeeded() {
                // still loading
            } else if updatedDate != wrapper.lastRefresh {
                refreshDisplay()
            }
        } else {
            isLocating = false

            if refreshNeeded() {
                launchURLSessionNow()
            } else if updatedDate != wrapper.lastRefresh {
                refreshDisplay()
            }
        }
    }

    func launchURLSessionNow() {
        #if DEBUG
            print("launchURLSessionNow")
        #endif

        let city = PreferenceHelper.getCityToUse()

        #if DEBUG
            print("launchURLSessionNow " + city.frenchName)
        #endif

        if !LocationServices.isUseCurrentLocation(city) {
            let url = URL(string: UrlHelper.getUrl(city))!

            let configObject = URLSessionConfiguration.default
            configObject.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            let session = URLSession(configuration: configObject)

            let task = session.dataTask(with: url) { [weak self] data, _, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error info: \(error)")
                        return
                    }
                    guard let data = data else { return }

                    self.wrapper = WeatherHelper.getWeatherInformationsNoCache(data, city: PreferenceHelper.getCityToUse())

                    #if DEBUG
                        print("Watch wrapper updated")
                    #endif

                    self.updateComplication()
                    self.scheduleRefresh(Constants.backgroundRefreshInSeconds)
                    self.refreshDisplay()
                }
            }
            task.resume()
        } else {
            print("launchURLSessionNow - no selected city")
        }
    }

    func refreshDisplay() {
        #if DEBUG
            print("refreshDisplay")
        #endif

        isLocating = false
        updatedDate = wrapper.lastRefresh

        #if ENABLE_PWS
        loadSyncedPWS()
        #endif

        #if ENABLE_WEATHERKIT
        if let city = wrapper.city {
            Task { @MainActor in
                if let data = await WeatherKitService.shared.fetchWeatherKitData(for: city) {
                    self.weatherKitData = data
                }
            }
        }
        #endif
    }

    // MARK: - City selection

    func cityDidChange(_ city: City) {
        #if DEBUG
            print("cityDidChange")
        #endif

        locationError = nil

        if LocationServices.isUseCurrentLocation(city) {
            #if DEBUG
                print("cityDidChange Locating")
            #endif

            isLocating = true
            resetWeather()

            locationCoordinator?.locationServices?.start()
            locationCoordinator?.locationServices?.updateCity(city)
        } else {
            #if DEBUG
                print("cityDidChange Loading")
            #endif

            isLocating = false
            resetWeather()

            PreferenceHelper.saveSelectedCity(city)
            locationCoordinator?.locationServices?.cityHasBeenUpdated(city)
        }

        PreferenceHelper.addFavorite(city)
    }

    func switchLanguage(_ language: Language) {
        PreferenceHelper.saveLanguage(language)
        resetWeather()
        loadData(showError: false)
    }

    // MARK: - PWS

    #if ENABLE_PWS
    nonisolated static func closestStationName(for city: City?) -> String? {
        guard let city = city else { return nil }

        let stations = PreferenceHelper.getPWSStations()
        guard !stations.isEmpty,
              PreferenceHelper.hasPWSCredentials(),
              let cityLat = Double(city.latitude),
              let cityLon = Double(city.longitude) else {
            return nil
        }

        let cityLocation = CLLocation(latitude: cityLat, longitude: cityLon)
        var closestName: String?
        var closestDistance: CLLocationDistance = .greatestFiniteMagnitude

        for station in stations {
            let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
            let distance = cityLocation.distance(from: stationLocation)
            guard distance < 50_000 else { continue }
            if distance < closestDistance {
                closestDistance = distance
                closestName = station.name
            }
        }

        return closestName
    }

    nonisolated static func syncedPWSData() -> (temperature: Int?, stationName: String?) {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        let stationName = defaults.string(forKey: Global.pwsStationNameKey)
        guard stationName != nil, defaults.object(forKey: Global.pwsTemperatureKey) != nil else {
            return (nil, nil)
        }
        return (defaults.integer(forKey: Global.pwsTemperatureKey), stationName)
    }

    private func loadSyncedPWS() {
        let synced = Self.syncedPWSData()
        self.pwsTemperature = synced.temperature
        self.pwsStationName = synced.stationName ?? Self.closestStationName(for: wrapper.city)
    }
    #endif

    // MARK: - Location delegate callbacks

    func handleCityUpdated(_ city: City) {
        launchURLSessionNow()
    }

    func handleLocatingCompleted() {
        isLocating = false
    }

    func handleLocationError(_ message: String) {
        isLocating = false
        locationError = message
        resetWeather()
    }

    func handleLocationNotAvailable() {
        loadData(showError: false)
    }

    func handleLocationSameCity() {
        refreshDisplay()
    }
}
