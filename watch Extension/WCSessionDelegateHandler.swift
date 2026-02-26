//
//  WCSessionDelegateHandler.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2026-02-17.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
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
        if let pwsTemp = applicationContext[Global.pwsTemperatureKey] as? Int {
            defaults.set(pwsTemp, forKey: Global.pwsTemperatureKey)
        }
        if let pwsStation = applicationContext[Global.pwsStationNameKey] as? String {
            defaults.set(pwsStation, forKey: Global.pwsStationNameKey)
        }
        #endif

        WeatherHelper.cache.removeAllObjects()

        Task { @MainActor in
            WatchWeatherModel.shared.resetWeather()
            WatchWeatherModel.shared.loadData(showError: false)
        }
    }
}
