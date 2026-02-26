//
//  WeatherKitService.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

#if ENABLE_WEATHERKIT
import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherKitService {
    static let shared = WeatherKitService()
    private let service = WeatherService.shared
    private let cache = ExpiringCache<WeatherKitData>()

    private init() {}

    func fetchWeatherKitData(for city: City) async -> WeatherKitData? {
        let cacheKey = city.id

        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        guard let lat = Double(city.latitude), let lon = Double(city.longitude) else {
            return nil
        }

        let location = CLLocation(latitude: lat, longitude: lon)

        do {
            let weather = try await service.weather(for: location, including: .current, .minute, .hourly, .daily)
            let today = weather.3.first
            let data = WeatherKitData(currentWeather: weather.0, minuteForecast: weather.1, hourlyForecast: weather.2, dailyForecast: weather.3, sunrise: today?.sun.sunrise, sunset: today?.sun.sunset)
            cache.setObject(data, forKey: cacheKey)
            return data
        } catch {
            #if DEBUG
            print("WeatherKit error: \(error)")
            #endif
            return nil
        }
    }
}
#endif
