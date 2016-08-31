//
//  WeatherUpdateDelegate.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-10.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

protocol WeatherUpdateDelegate : class {
    func weatherDidUpdate(_ wrapper: WeatherInformationWrapper)
    func beforeUpdate()
    func weatherShouldUpdate()
}
