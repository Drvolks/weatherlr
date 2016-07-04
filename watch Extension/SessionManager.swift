//
//  SessionManager.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-03.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchConnectivity
import ClockKit

class SessionManager : NSObject, WCSessionDelegate{
    private let watchSession: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    static let instance = SessionManager()
    
    private var cityChangeDelegates = [CityChangeDelegate]()
    
    override init(){
        super.init()
        
        if WCSession.isSupported() {
            watchSession!.delegate = self
            watchSession!.activateSession()
        }
    }
    
    func addDelegate(delegate: CityChangeDelegate) {
        cityChangeDelegates.append(delegate)
    }
    
    func removeDelegate(delegate: CityChangeDelegate) {
        for (index, cityDelegate) in cityChangeDelegates.enumerate() {
            if cityDelegate === delegate {
                cityChangeDelegates.removeAtIndex(index)
                break
            }
        }
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        if let nsData = userInfo[Constants.selectedCityKey] as? NSData {
            let data = NSKeyedUnarchiver.unarchiveObjectWithData(nsData)
            if let city = data as? City {
                var doRefresh = true
                if let oldCity = PreferenceHelper.getSelectedCity() {
                    if oldCity.id == city.id {
                        doRefresh = false
                    }
                }
                
                if doRefresh {
                    PreferenceHelper.saveSelectedCity(city)
                    
                    cityChangeDelegates.forEach({
                        $0.cityDidUpdate(city)
                    })
                    
                    let complicationServer = CLKComplicationServer.sharedInstance()
                    for complication in complicationServer.activeComplications! {
                        complicationServer.reloadTimelineForComplication(complication)
                    }
                }
            }
        }
    }
}