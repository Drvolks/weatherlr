//
//  WeatherInformationWrapper.swift
//  weatherlr
//
//  Created by drvolks on 2016-05-01.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

public class WeatherInformationWrapper {
    public var weatherInformations:[WeatherInformation]
    public var lastRefresh:Date
    public var alerts:[AlertInformation]
    public var hourlyForecasts:[HourlyForecastInfo]
    public var city:City?
    public var initialState = true

    public init() {
        self.weatherInformations = [WeatherInformation]()
        self.lastRefresh = Date(timeIntervalSince1970: 0)
        self.alerts = [AlertInformation]()
        self.hourlyForecasts = [HourlyForecastInfo]()
        self.city = nil
        self.initialState = true
    }

    public init(weatherInformations:[WeatherInformation], alerts:[AlertInformation], hourlyForecasts:[HourlyForecastInfo] = [], city:City) {
        self.weatherInformations = weatherInformations
        self.lastRefresh = Date()
        self.alerts = alerts
        self.hourlyForecasts = hourlyForecasts
        self.city = city
        self.initialState = false
    }
    
    public func expired() -> Bool {
        let elapsedTime = Calendar.current.dateComponents([.minute], from: lastRefresh as Date, to: Date()).minute
        if elapsedTime! < Global.expirationInMinutes {
            return false
        } else {
            return true
        }
    }
    
    public func expiredTooLongAgo() -> Bool {
        let elapsedTime = Calendar.current.dateComponents([.minute], from: lastRefresh as Date, to: Date()).minute
        if elapsedTime! < (Global.expirationInMinutes * 3) {
            return false
        } else {
            return true
        }
    }
    
    public func refreshNeeded() -> Bool {
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
