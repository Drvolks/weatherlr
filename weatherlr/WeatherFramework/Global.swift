//
//  Global.swift
//  WeatherFramework
//
//  Created by Jean-Francois Dufour on 17-10-03.
//  Copyright © 2017 Jean-Francois Dufour. All rights reserved.
//

import Foundation

public struct Global {
    public static let weatherCacheInMinutes = 30
    public static let expirationInMinutes = 30
    public static let expirationLocationInMinutes = 60
    public static let selectedCityKey = "selectedCity"
    public static let lastLocatedCityKey = "lastLocatedCity"
    public static let favotiteCitiesKey = "favoriteCities"
    public static let languageKey = "lang"
    public static let versionKey = "version"
    public static let SettingGroup = "group.com.massawippi.weatherlr"
    public static let currentLocationCityId = "currentLocation"
    public static let locationDistance = Double(5000) // 5 km
    public static let currentLocationMaxDistance = Double(1000000) // 1000 km
}
