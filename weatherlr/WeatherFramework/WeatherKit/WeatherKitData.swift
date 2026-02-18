//
//  WeatherKitData.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

#if ENABLE_WEATHERKIT
import Foundation
import WeatherKit

struct WeatherKitData {
    let currentWeather: CurrentWeather
    let minuteForecast: WeatherKit.Forecast<MinuteWeather>?
    let hourlyForecast: WeatherKit.Forecast<HourWeather>
    let sunrise: Date?
    let sunset: Date?

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

    func isDaylight(at date: Date = Date()) -> Bool {
        if let sunrise = sunrise, let sunset = sunset {
            return date >= sunrise && date < sunset
        }
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 7 && hour < 19
    }
}
#endif
