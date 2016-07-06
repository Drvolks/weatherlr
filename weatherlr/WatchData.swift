//
//  WatchData.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchData: NSObject, WCSessionDelegate {
    private let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    static let instance = WatchData()
    
    override init(){
        super.init()
        
        if WCSession.isSupported() {
            session!.delegate = self
            session!.activateSession()
        }
    }
    
    func updateCity(city:City) {
        if let session = session {
            if session.paired && session.watchAppInstalled {
                var refreshWatch = false
                if let watchCity = PreferenceHelper.getWatchCity() {
                    if watchCity.id != city.id {
                        refreshWatch = true
                    }
                } else {
                    refreshWatch = true
                }
                
                if refreshWatch {
                    let data = NSKeyedArchiver.archivedDataWithRootObject(city)
                    let lang = PreferenceHelper.getLanguage().rawValue
                    session.transferUserInfo([Constants.selectedCityKey: data, Constants.languageKey: lang])
                    
                    PreferenceHelper.saveWatchCity(city)
                }
            }
        }
    }
    
    func updateLanguage() {
        if let session = session {
            if session.paired && session.watchAppInstalled {
                let city = PreferenceHelper.getSelectedCity()!
                let data = NSKeyedArchiver.archivedDataWithRootObject(city)
                let lang = PreferenceHelper.getLanguage().rawValue
                session.transferUserInfo([Constants.selectedCityKey: data, Constants.languageKey: lang])
                
                PreferenceHelper.saveWatchCity(city)
            }
        }
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        if let city = PreferenceHelper.getSelectedCity() {
            PreferenceHelper.removeWatchCity()
            updateCity(city)
        }
    }
}