//
//  LocationServicesDelegate.swift
//  WeatherFramework
//
//  Created by drvolks on 18-04-01.
//  Copyright © 2018 drvolks. All rights reserved.
//

import Foundation

protocol LocationServicesDelegate {
    func cityHasBeenUpdated(_ city: City)
    func getAllCityList() -> [City]
    func unknownCity(_ cityName:String)
    func notInCanada()
    func errorLocating(_ errorCode:Int)
    func locationNotAvailable()
}
