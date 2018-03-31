//
//  LocationData.swift
//  WeatherFramework
//
//  Created by drvolks on 18-03-30.
//  Copyright © 2018 drvolks. All rights reserved.
//

import Foundation

class LocationData {
    var cityName:String
    var country:String?
    
    init(cityName:String) {
        self.cityName = cityName
    }
}
