//
//  WeatherChangeDelegate.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-03.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

protocol CityChangeDelegate {
    func cityDidUpdate(city: City)
}