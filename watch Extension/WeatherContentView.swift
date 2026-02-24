//
//  WeatherContentView.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2026-02-24.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import SwiftUI

struct WeatherContentView: View {
    @State private var model = WatchWeatherModel.shared
    @State private var showCityPicker = false
    @State private var cityPickerCities: [City] = []
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 4) {
                    // City header
                    cityHeader
                        .id("top")

                    if model.isLocating {
                        Image("WatchLocating")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 100)
                            .frame(maxWidth: .infinity)
                    }

                    // Weather rows
                    if !model.wrapper.weatherInformations.isEmpty {
                        weatherList
                    }

                    // Error label
                    if let error = model.locationError {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Select city button
                    Button("Select city".localized()) {
                        selectCity()
                    }

                    // Last refresh time
                    if !model.wrapper.weatherInformations.isEmpty {
                        Text(WeatherHelper.getRefreshTime(model.wrapper))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Language buttons
                    HStack {
                        Button("Français") {
                            model.switchLanguage(.French)
                        }
                        .frame(maxWidth: .infinity)

                        Button("English") {
                            model.switchLanguage(.English)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .environment(model)
        .onAppear {
            setupModel()
            model.loadData(showError: false)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                model.loadData(showError: false)
            }
        }
        .sheet(isPresented: $showCityPicker) {
            CityPickerView(cities: cityPickerCities) { city in
                PreferenceHelper.addFavorite(city)
                model.resetWeather()
                model.cityDidChange(city)
            }
        }
    }

    private var cityHeader: some View {
        HStack(spacing: 2) {
            Text(cityName)
                .lineLimit(1)

            #if ENABLE_PWS
            if model.pwsStationName != nil {
                Image(systemName: "sensor.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            #endif
        }
    }

    @ViewBuilder
    private var weatherList: some View {
        let informations = model.wrapper.weatherInformations
        ForEach(Array(informations.enumerated()), id: \.offset) { index, weather in
            if weather.weatherDay == WeatherDay.now {
                CurrentWeatherRow(
                    weather: weather,
                    nextWeather: index + 1 < informations.count ? informations[index + 1] : nil
                )
            } else if weather.weatherDay == WeatherDay.today {
                NextWeatherRow(
                    weather: weather,
                    previousWeatherPresent: index > 0
                )
            } else {
                WeatherRow(weather: weather)
            }
        }
    }

    private var cityName: String {
        if model.isLocating {
            return "Locating".localized()
        }

        if model.wrapper.weatherInformations.isEmpty {
            return "Loading".localized()
        }

        guard let city = model.wrapper.city else {
            return "Loading".localized()
        }

        #if ENABLE_PWS
        if let stationName = model.pwsStationName {
            return stationName
        }
        #endif

        return CityHelper.cityName(city)
    }

    private func setupModel() {
        if model.locationCoordinator == nil {
            model.locationCoordinator = LocationCoordinator()
        }
    }

    private func selectCity() {
        var cityNames = [String]()
        let isFrench = PreferenceHelper.isFrench()
        PreferenceHelper.getFavoriteCities().forEach {
            if $0.id == Global.currentLocationCityId {
                if isFrench {
                    cityNames.append($0.frenchName)
                } else {
                    cityNames.append($0.englishName)
                }
            } else {
                if isFrench {
                    cityNames.append($0.frenchName + ", " + $0.province.uppercased())
                } else {
                    cityNames.append($0.englishName + ", " + $0.province.uppercased())
                }
            }
        }

        cityNames.append(contentsOf: "abcdefghijklmnopqrstuvwxyz".uppercased().map { String($0) })

        // Use WatchKit text input
        WKApplication.shared().visibleInterfaceController?.presentTextInputController(withSuggestions: cityNames, allowedInputMode: .plain) { result in
            Task { @MainActor in
                self.handleCityInput(result)
            }
        }
    }

    private func handleCityInput(_ result: [Any]?) {
        guard let result = result, let choice = result[0] as? String else { return }

        // Check favorites
        for city in PreferenceHelper.getFavoriteCities() {
            let name = CityHelper.cityName(city) + ", " + city.province.uppercased()
            if name == choice {
                if city.id != PreferenceHelper.getSelectedCity().id {
                    model.cityDidChange(city)
                }
                return
            }
        }

        // Check current location
        let useCurrentCity = CityHelper.getCurrentLocationCity()
        if choice == useCurrentCity.englishName || choice == useCurrentCity.frenchName {
            model.cityDidChange(useCurrentCity)
            return
        }

        // Search
        let allCities = model.locationCoordinator?.locationServices?.getAllCityList() ?? CityHelper.loadAllCities()
        let cities: [City]
        if choice.count == 1 {
            cities = CityHelper.searchCityStartingWith(choice, allCityList: allCities)
        } else {
            cities = CityHelper.searchCity(choice, allCityList: allCities)
        }

        if cities.count == 1 {
            model.cityDidChange(cities[0])
        } else {
            cityPickerCities = cities
            showCityPicker = true
        }
    }
}
