//
//  LocationData.swift
//  WeatherFramework
//
//  Created by Jean-Francois Dufour on 18-03-30.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class LocationData {
    var cityName:String
    var country:String?
    
    init(cityName:String) {
        self.cityName = cityName
    }
}
