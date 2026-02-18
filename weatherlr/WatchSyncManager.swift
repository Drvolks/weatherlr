//
//  WatchSyncManager.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2026-02-17.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchSyncManager: NSObject, @preconcurrency WCSessionDelegate {
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
        guard WCSession.isSupported() else {
            #if DEBUG
            print("WatchSync: WCSession not supported")
            #endif
            return
        }
        let session = WCSession.default
        guard session.activationState == .activated else {
            #if DEBUG
            print("WatchSync: session not activated (state: \(session.activationState.rawValue))")
            #endif
            return
        }

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
            #if DEBUG
            let stations = (try? JSONDecoder().decode([PWSStation].self, from: pwsData)) ?? []
            print("WatchSync: sending \(stations.count) PWS station(s): \(stations.map { $0.stationId })")
            #endif
        } else {
            #if DEBUG
            print("WatchSync: no PWS stations data in UserDefaults")
            #endif
        }
        if let apiKey = PreferenceHelper.getPWSApiKey() {
            context["pwsApiKey"] = apiKey
        }
        #endif

        do {
            try session.updateApplicationContext(context)
            #if DEBUG
            print("WatchSync: updateApplicationContext succeeded with \(context.count) keys: \(context.keys.sorted())")
            #endif
        } catch {
            #if DEBUG
            print("WatchSync: updateApplicationContext FAILED: \(error)")
            #endif
        }
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
