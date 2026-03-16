//
//  WeatherKitData.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

#if ENABLE_PRECIPITATION
import Foundation
import WeatherKit

struct PrecipitationData {
    let minuteForecast: WeatherKit.Forecast<MinuteWeather>?

    var hasPrecipitationNextHour: Bool {
        guard let minutes = minuteForecast else { return false }
        return minutes.contains { $0.precipitationChance > 0 }
    }

    var precipitationMinutes: [(minuteOffset: Int, intensity: Double)] {
        guard let minutes = minuteForecast else { return [] }
        return minutes.enumerated().map { (index, minute) in
            let intensity = minute.precipitationIntensity.value * minute.precipitationChance
            return (minuteOffset: index, intensity: intensity)
        }
    }
}
#endif
