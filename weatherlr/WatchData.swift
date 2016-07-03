//
//  WatchData.swift
//  weatherlr
//
//  Created by drvolks on 2016-07-02.
//  Copyright © 2016 drvolks. All rights reserved.
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
        if session != nil && session!.paired && session!.watchAppInstalled {
            let data = NSKeyedArchiver.archivedDataWithRootObject(city)
            session!.transferUserInfo([Constants.selectedCityKey: data])
        }
    }
}