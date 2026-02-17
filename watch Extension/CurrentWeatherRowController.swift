//
//  CurrentWeatherRowController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit

class CurrentWeatherRowController : NSObject {
    @IBOutlet var weatherImage: WKInterfaceImage!
    @IBOutlet var currentTemperatureLabel: WKInterfaceLabel!
    @IBOutlet var minMaxImage: WKInterfaceImage!

    var nextWeather:WeatherInformation?
    #if ENABLE_PWS
    var pwsTemperature: Int?
    #endif
    var weather:WeatherInformation? {
        didSet {
            if let weather = weather {
                #if ENABLE_PWS
                let temperature = pwsTemperature ?? weather.temperature
                #else
                let temperature = weather.temperature
                #endif
                let currentTemperature = "Currently".localized() + " " + String(temperature) + "°"

                if weather.weatherDay == WeatherDay.now {
                    currentTemperatureLabel.setText(currentTemperature)
                } else {
                    currentTemperatureLabel.setText("")
                }

                if let nextWeather = nextWeather {
                    minMaxImage.setImage(WeatherHelper.textToImageMinMax(nextWeather))
                } else {
                    minMaxImage.setImage(nil)
                }

                weatherImage.setImage(weather.image())
            }
        }
    }
}
