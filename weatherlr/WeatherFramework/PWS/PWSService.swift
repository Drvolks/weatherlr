//
//  PWSService.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import CoreLocation

@MainActor
class PWSService {
    static let shared = PWSService()
    private let cache = ExpiringCache<WUObservation>()

    private init() {}

    func fetchObservation(for stationId: String) async -> WUObservation? {
        let cacheKey = "pws_\(stationId)"

        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        guard let apiKey = PreferenceHelper.getPWSApiKey() else {
            return nil
        }

        let urlString = "https://api.weather.com/v2/pws/observations/current?stationId=\(stationId)&format=json&units=e&apiKey=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(WUResponse.self, from: data)
            if let observation = response.observations?.first {
                cache.setObject(observation, forKey: cacheKey)
                return observation
            }
        } catch {
            #if DEBUG
            print("PWSService error for \(stationId): \(error)")
            #endif
        }

        return nil
    }

    func findClosestStation(to city: City) async -> (station: PWSStation, observation: WUObservation)? {
        let stations = PreferenceHelper.getPWSStations()
        guard !stations.isEmpty,
              PreferenceHelper.hasPWSCredentials(),
              let cityLat = Double(city.latitude),
              let cityLon = Double(city.longitude) else {
            return nil
        }

        let cityLocation = CLLocation(latitude: cityLat, longitude: cityLon)

        var closest: (station: PWSStation, observation: WUObservation, distance: CLLocationDistance)?

        for station in stations {
            guard let observation = await fetchObservation(for: station.stationId) else { continue }

            let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
            let distance = cityLocation.distance(from: stationLocation)

            // Only consider stations within 50km
            guard distance < 50_000 else { continue }

            if closest == nil || distance < closest!.distance {
                closest = (station, observation, distance)
            }
        }

        if let closest = closest {
            return (closest.station, closest.observation)
        }

        return nil
    }
}
