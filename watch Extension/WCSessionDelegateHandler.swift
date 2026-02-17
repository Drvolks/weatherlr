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
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        #if DEBUG
            print("Received applicationContext from iPhone")
        #endif

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
        #endif

        WeatherHelper.cache.removeAllObjects()
    }
}
