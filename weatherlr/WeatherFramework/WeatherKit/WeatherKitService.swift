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
            let weather = try await service.weather(for: location, including: .minute, .hourly)
            let data = WeatherKitData(minuteForecast: weather.0, hourlyForecast: weather.1)
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
