//
//  LocatedCity.swift
//  WeatherFramework
//
//  Created by Jean-Francois Dufour on 18-04-02.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
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
