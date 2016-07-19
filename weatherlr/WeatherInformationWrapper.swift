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
        self.lastRefresh = Date()
        self.alerts = [AlertInformation]()
        self.city = nil
    }
    
    init(weatherInformations:[WeatherInformation], alerts:[AlertInformation], city:City) {
        self.weatherInformations = weatherInformations
        self.lastRefresh = Date()
        self.alerts = alerts
        self.city = city
    }
}
