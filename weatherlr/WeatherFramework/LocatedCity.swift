//
//  LocatedCity.swift
//  WeatherFramework
//
//  Created by drvolks on 18-04-02.
//  Copyright © 2018 drvolks. All rights reserved.
//

import Foundation
import MapKit

class LocatedCity {
    var city:City
    var location:CLLocation
    
    init(city:City, location:CLLocation) {
        self.city = city
        self.location = location
    }
}
