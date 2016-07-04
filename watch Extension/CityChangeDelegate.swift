//
//  WeatherChangeDelegate.swift
//  weatherlr
//
//  Created by drvolks on 2016-07-03.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

protocol CityChangeDelegate : class {
    func cityDidUpdate(city: City)
}