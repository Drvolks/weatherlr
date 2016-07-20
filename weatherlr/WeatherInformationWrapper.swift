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
    
    init() {
        self.weatherInformations = [WeatherInformation]()
        self.lastRefresh = Date(timeIntervalSince1970: 0)
        self.alerts = [AlertInformation]()
        self.city = nil
    }
    
    init(weatherInformations:[WeatherInformation], alerts:[AlertInformation], city:City) {
        self.weatherInformations = weatherInformations
        self.lastRefresh = Date()
        self.alerts = alerts
        self.city = city
    }
    
    func expired() -> Bool {
        let elapsedTime = Calendar.current.components(.minute, from: lastRefresh as Date, to: Date(), options: []).minute
        if elapsedTime < Constants.WeatherCacheInMinutes {
            return false
        } else {
            return true
        }
    }
    
    func refreshNeeded() -> Bool {
        if let oldCity = city {
            if let currentCity = PreferenceHelper.getSelectedCity() {
                if expired() {
                    return true
                }
                else if oldCity.id != currentCity.id {
                    return true
                }
                
                return false
            }
        }
        
        return true
    }
}
