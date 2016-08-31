//
//  WeatherUpdateDelegate.swift
//  weatherlr
//
//  Created by drvolks on 2016-07-10.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

protocol WeatherUpdateDelegate : class {
    func weatherDidUpdate(_ wrapper: WeatherInformationWrapper)
    func beforeUpdate()
    func weatherShouldUpdate()
}
