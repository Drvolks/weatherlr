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
    @IBOutlet var detailLine2Label: WKInterfaceLabel!
    @IBOutlet var minMaxImage: WKInterfaceImage!
    
    var previousWeatherPresent = true
    var weather:WeatherInformation? {
        didSet {
            if let weather = weather {
                weatherLabel.setText(WeatherHelper.getWeatherDayWhenText(weather))
                weatherImage.setImage(weather.image())
                detailLabel.setText(weather.detail)
                
                if previousWeatherPresent {
                    minMaxImage.setHidden(true)
                } else {
                    minMaxImage.setHidden(false)
                    minMaxImage.setImage(WeatherHelper.textToImageMinMax(weather))
                }
                
                if let range = weather.detail.rangeOfString(".") {
                    let line1 = String(weather.detail.characters.prefixUpTo(range.startIndex)).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    let line2 = String(weather.detail.characters.suffixFrom(range.endIndex)).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    
                    detailLabel.setText(line1)
                    detailLine2Label.setText(line2)
                } else {
                    detailLabel.setText(weather.detail)
                    detailLine2Label.setText("")
                }
            }
        }
    }
    
    
}