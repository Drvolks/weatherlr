//
//  CurrentWeatherRowController.swift
//  weatherlr
//
//  Created by drvolks on 2016-07-02.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation
import WatchKit

class CurrentWeatherRowController : NSObject {
    @IBOutlet var weatherImage: WKInterfaceImage!
    @IBOutlet var currentTemperatureLabel: WKInterfaceLabel!
    @IBOutlet var minMaxImage: WKInterfaceImage!
    
    var nextWeather:WeatherInformation?
    var weather:WeatherInformation? {
        didSet {
            if let weather = weather {
                let currentTemperature = "Currently".localized() + " " + String(weather.temperature) + "°"
                
                if weather.weatherDay == WeatherDay.Now {
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
