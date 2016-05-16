//
//  WeatherInformationWrapper.swift
//  weatherlr
//
//  Created by drvolks on 2016-05-01.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

class WeatherInformationWrapper {
    var weatherInformations:[WeatherInformation]
    var lastRefresh:NSDate
    var alerts:[AlertInformation]
    
    init() {
        self.weatherInformations = [WeatherInformation]()
        self.lastRefresh = NSDate()
        self.alerts = [AlertInformation]()
    }
    
    init(weatherInformations:[WeatherInformation], alerts:[AlertInformation]) {
        self.weatherInformations = weatherInformations
        self.lastRefresh = NSDate()
        self.alerts = alerts
    }
}