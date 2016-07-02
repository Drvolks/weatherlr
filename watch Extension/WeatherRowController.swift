//
//  WeatherRowController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit

class WeatherRowController : NSObject {
    @IBOutlet var weatherLabel: WKInterfaceLabel!
    @IBOutlet var weatherImage: WKInterfaceImage!
    @IBOutlet var minMaxLabel: WKInterfaceLabel!
    @IBOutlet var minMaxImage: WKInterfaceImage!
    
    var rowIndex:Int?
    var weather:WeatherInformation? {
        didSet {
            if let weather = weather {
                weatherLabel.setText(WeatherHelper.getWeatherDayWhenText(weather))
                minMaxLabel.setText(String(weather.temperature))
                weatherImage.setImage(weather.image())
                minMaxImage.setImage(WeatherHelper.getMinMaxImage(weather, header: false))
            }
        }
    }
}