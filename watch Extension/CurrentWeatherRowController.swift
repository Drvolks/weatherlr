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
    @IBOutlet var minMaxLabel: WKInterfaceLabel!
    
    var nextWeather:WeatherInformation?
    var weather:WeatherInformation? {
        didSet {
            if let weather = weather {
                if weather.weatherDay == WeatherDay.Now {
                    currentTemperatureLabel.setText(String(weather.temperature))
                } else {
                    currentTemperatureLabel.setText("")
                }
                
                if let nextWeather = nextWeather {
                    minMaxLabel.setText(String(nextWeather.temperature))
                } else {
                    minMaxLabel.setText("")
                }
                
                weatherImage.setImage(weather.image())
            }
        }
    }
}
