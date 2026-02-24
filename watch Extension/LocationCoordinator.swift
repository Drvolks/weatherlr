//
//  LocationCoordinator.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2026-02-24.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class LocationCoordinator: LocationServicesDelegate {
    var locationServices: LocationServices?

    init() {
        locationServices = LocationServices()
        locationServices?.delegate = self
    }

    func cityHasBeenUpdated(_ city: City) {
        Task { @MainActor in
            WatchWeatherModel.shared.handleCityUpdated(city)
        }
    }

    func getAllCityList() -> [City] {
        return CityHelper.loadAllCities()
    }

    func unknownCity(_ cityName: String) {
        let message = "The iPhone detected that you are located in".localized() + " " + cityName + ", " + "but this city is not in the Environment Canada list. Do you want to select a city yourself?".localized()
        Task { @MainActor in
            WatchWeatherModel.shared.handleLocationError(message)
        }
    }

    func notInCanada(_ country: String) {
        #if DEBUG
            print("notInCanada")
        #endif
        let message = "The iPhone detected that you are not located in Canada".localized()
        Task { @MainActor in
            WatchWeatherModel.shared.handleLocationError(message)
        }
    }

    func errorLocating(_ errorCode: Int) {
        let message = "Unable to detect your current location".localized()
        Task { @MainActor in
            WatchWeatherModel.shared.handleLocationError(message)
        }
    }

    func locationNotAvailable() {
        Task { @MainActor in
            WatchWeatherModel.shared.handleLocationNotAvailable()
        }
    }

    func locatingCompleted() {
        #if DEBUG
            print("locatingCompleted")
        #endif
        Task { @MainActor in
            WatchWeatherModel.shared.handleLocatingCompleted()
        }
    }

    func locationSameCity() {
        Task { @MainActor in
            WatchWeatherModel.shared.handleLocationSameCity()
        }
    }
}
