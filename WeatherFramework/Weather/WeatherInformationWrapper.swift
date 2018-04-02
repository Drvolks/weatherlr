//
//  WeatherInformationWrapper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-01.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class WeatherInformationWrapper {
    var weatherInformations:[WeatherInformation]
    var lastRefresh:Date
    var alerts:[AlertInformation]
    var city:City?
    var initialState = true
    
    init() {
        self.weatherInformations = [WeatherInformation]()
        self.lastRefresh = Date(timeIntervalSince1970: 0)
        self.alerts = [AlertInformation]()
        self.city = nil
        self.initialState = true
    }
    
    init(weatherInformations:[WeatherInformation], alerts:[AlertInformation], city:City) {
        self.weatherInformations = weatherInformations
        self.lastRefresh = Date()
        self.alerts = alerts
        self.city = city
        self.initialState = false
    }
    
    func expired() -> Bool {
        let elapsedTime = Calendar.current.dateComponents([.minute], from: lastRefresh as Date, to: Date()).minute
        if elapsedTime! < Global.expirationInMinutes {
            return false
        } else {
            return true
        }
    }
    
    func expiredTooLongAgo() -> Bool {
        let elapsedTime = Calendar.current.dateComponents([.minute], from: lastRefresh as Date, to: Date()).minute
        if elapsedTime! < (Global.expirationInMinutes * 3) {
            return false
        } else {
            return true
        }
    }
    
    func refreshNeeded() -> Bool {
        if initialState || weatherInformations.count == 0 {
            return true
        }
        
        if let oldCity = city {
            let currentCity = PreferenceHelper.getCityToUse()
                if expired() {
                    return true
                }
                else if oldCity.id != currentCity.id {
                    return true
                }
                
                return false
        }
        
        return true
    }
}
