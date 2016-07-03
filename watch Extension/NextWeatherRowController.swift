//
//  NextWeatherRow.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-03.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit

class NextWeatherRowController : NSObject {
    @IBOutlet var weatherLabel: WKInterfaceLabel!
    @IBOutlet var detailLabel: WKInterfaceLabel!
    @IBOutlet var weatherImage: WKInterfaceImage!
    @IBOutlet var minMaxLabel: WKInterfaceLabel!
    
    var rowIndex:Int?
    var weather:WeatherInformation? {
        didSet {
            if let weather = weather {
                weatherLabel.setText(WeatherHelper.getWeatherDayWhenText(weather))
                minMaxLabel.setText(String(weather.temperature) + "°")
                weatherImage.setImage(weather.image())
                detailLabel.setText(weather.detail)
            }
        }
    }
}