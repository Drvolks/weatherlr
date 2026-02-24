//
//  WatchSyncManager.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2026-02-17.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchSyncManager: NSObject, WCSessionDelegate {
    nonisolated(unsafe) static let shared = WatchSyncManager()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func syncSettings() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        let defaults = UserDefaults(suiteName: Global.SettingGroup)!
        var context: [String: Any] = [:]

        if let selectedCityData = defaults.data(forKey: Global.selectedCityKey) {
            context[Global.selectedCityKey] = selectedCityData
        }
        if let favoriteCitiesData = defaults.data(forKey: Global.favotiteCitiesKey) {
            context[Global.favotiteCitiesKey] = favoriteCitiesData
        }
        if let language = defaults.string(forKey: Global.languageKey) {
            context[Global.languageKey] = language
        }
        if let lastLocatedCityData = defaults.data(forKey: Global.lastLocatedCityKey) {
            context[Global.lastLocatedCityKey] = lastLocatedCityData
        }

        #if ENABLE_PWS
        if let pwsData = defaults.data(forKey: Global.pwsStationsKey) {
            context[Global.pwsStationsKey] = pwsData
        }
        if let apiKey = PreferenceHelper.getPWSApiKey() {
            context["pwsApiKey"] = apiKey
        }
        #endif

        try? session.updateApplicationContext(context)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            syncSettings()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
