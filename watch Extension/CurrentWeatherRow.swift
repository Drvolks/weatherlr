//
//  CurrentWeatherRow.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2026-02-24.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import SwiftUI

struct CurrentWeatherRow: View {
    let weather: WeatherInformation
    let nextWeather: WeatherInformation?
    @Environment(WatchWeatherModel.self) private var model

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(uiImage: weatherImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 50)

                Spacer()

                if let nextWeather = nextWeather {
                    Image(uiImage: WeatherHelper.textToImageMinMax(nextWeather))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
            }

            if weather.weatherDay == WeatherDay.now {
                Text(temperatureText)
                    .font(.body)
            }
        }
        .padding(5)
        .background(Color.white.opacity(0.15))
        .cornerRadius(8)
    }

    private var temperatureText: String {
        #if ENABLE_PWS
        let temperature = model.pwsTemperature ?? weather.temperature
        #else
        let temperature = weather.temperature
        #endif
        return "Currently".localized() + " " + String(temperature) + "°"
    }

    private var weatherImage: UIImage {
        #if ENABLE_WEATHERKIT
        if let data = model.weatherKitData {
            let night = !data.isDaylight()
            return WeatherHelper.image(for: data.currentWeather.condition, night: night)
        }
        #endif
        return weather.image()
    }
}
