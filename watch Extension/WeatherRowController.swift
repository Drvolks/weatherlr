//
//  WeatherRowController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit
import WeatherFramework

class WeatherRowController : NSObject {
    @IBOutlet var weatherLabel: WKInterfaceLabel!
    @IBOutlet var weatherImage: WKInterfaceImage!
    @IBOutlet var minMaxImage: WKInterfaceImage!
    
    var rowIndex:Int?
    var weather:WeatherInformation? {
        didSet {
            if let weather = weather {
                weatherLabel.setText(WeatherHelper.getWeatherDayWhenText(weather))
                minMaxImage.setImage(WeatherHelper.textToImageMinMax(weather))
                weatherImage.setImage(weather.image())
            }
        }
    }
}
