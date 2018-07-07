//
//  LocationServicesDelegate.swift
//  WeatherFramework
//
//  Created by Jean-Francois Dufour on 18-04-01.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
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
