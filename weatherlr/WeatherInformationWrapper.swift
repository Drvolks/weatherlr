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
    
    init() {
        self.weatherInformations = [WeatherInformation]()
        self.lastRefresh = NSDate()
    }
    
    init(weatherInformations:[WeatherInformation]) {
        self.weatherInformations = weatherInformations
        self.lastRefresh = NSDate()
    }
}