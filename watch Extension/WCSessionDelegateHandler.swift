//
//  WCSessionDelegateHandler.swift
//  watch Extension
//
//  Created by drvolks on 2026-02-17.
//  Copyright © 2026 drvolks. All rights reserved.
//

import Foundation
import WatchConnectivity

class WCSessionDelegateHandler: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if DEBUG
            print("WCSession activation: \(activationState.rawValue)")
        #endif

        if activationState == .activated {
            let existingContext = session.receivedApplicationContext
            if !existingContext.isEmpty {
                #if DEBUG
                    print("Processing existing applicationContext on activation")
                #endif
                applyApplicationContext(existingContext)
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        #if DEBUG
            print("Received applicationContext from iPhone")
        #endif

        applyApplicationContext(applicationContext)
    }

    private func applyApplicationContext(_ applicationContext: [String : Any]) {
        let defaults = UserDefaults(suiteName: Global.SettingGroup)!

        if let data = applicationContext[Global.selectedCityKey] as? Data {
            defaults.set(data, forKey: Global.selectedCityKey)
        }
        if let data = applicationContext[Global.favotiteCitiesKey] as? Data {
            defaults.set(data, forKey: Global.favotiteCitiesKey)
        }
        if let lang = applicationContext[Global.languageKey] as? String {
            defaults.set(lang, forKey: Global.languageKey)
        }
        if let data = applicationContext[Global.lastLocatedCityKey] as? Data {
            defaults.set(data, forKey: Global.lastLocatedCityKey)
        }

        #if ENABLE_PWS
        if let data = applicationContext[Global.pwsStationsKey] as? Data {
            defaults.set(data, forKey: Global.pwsStationsKey)
        }
        if let apiKey = applicationContext["pwsApiKey"] as? String {
            defaults.set(apiKey, forKey: "pwsApiKey")
        }
        // The iPhone rebuilds the full context from its defaults on every sync, and writes
        // the reading keys (temperature / station name / timestamp) as an atomic group. Mirror
        // that here: when the context carries no reading, clear all three so a stale reading
        // can't linger on the Watch after the iPhone has stopped reporting one.
        if let pwsTemp = applicationContext[Global.pwsTemperatureKey] as? Int {
            defaults.set(pwsTemp, forKey: Global.pwsTemperatureKey)
            if let pwsStation = applicationContext[Global.pwsStationNameKey] as? String {
                defaults.set(pwsStation, forKey: Global.pwsStationNameKey)
            } else {
                defaults.removeObject(forKey: Global.pwsStationNameKey)
            }
            if let pwsUpdatedAt = applicationContext[Global.pwsTemperatureUpdatedAtKey] as? TimeInterval {
                defaults.set(pwsUpdatedAt, forKey: Global.pwsTemperatureUpdatedAtKey)
            } else {
                defaults.removeObject(forKey: Global.pwsTemperatureUpdatedAtKey)
            }
        } else {
            defaults.removeObject(forKey: Global.pwsTemperatureKey)
            defaults.removeObject(forKey: Global.pwsStationNameKey)
            defaults.removeObject(forKey: Global.pwsTemperatureUpdatedAtKey)
        }
        #endif

        WeatherHelper.cache.removeAllObjects()

        Task { @MainActor in
            WatchWeatherModel.shared.resetWeather()
            WatchWeatherModel.shared.loadData(showError: false)
        }
    }
}
