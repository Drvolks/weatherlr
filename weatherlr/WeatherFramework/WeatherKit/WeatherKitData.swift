//
//  WeatherKitData.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WeatherKit

struct WeatherKitData {
    let minuteForecast: WeatherKit.Forecast<MinuteWeather>?
    let hourlyForecast: WeatherKit.Forecast<HourWeather>

    var hasPrecipitationNextHour: Bool {
        guard let minutes = minuteForecast else { return false }
        return minutes.contains { $0.precipitationChance > 0 }
    }

    var precipitationMinutes: [(minuteOffset: Int, intensity: Double)] {
        guard let minutes = minuteForecast else { return [] }
        return minutes.enumerated().map { (index, minute) in
            (minuteOffset: index, intensity: minute.precipitationIntensity.value)
        }
    }

    var next24Hours: [HourWeather] {
        let now = Date()
        return hourlyForecast
            .filter { $0.date >= now }
            .prefix(24)
            .map { $0 }
    }
}
