//
//  WatchTemplateGraphicCorner.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2018-10-04.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit

class ComplicationTemplateGraphicCorner: ComplicationTemplate, ComplicationTemplateProtocol {
    func generate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplate {
        let modularTemplate = initialState() as! CLKComplicationTemplateGraphicCornerGaugeText
        
        if let weather = weather {
            modularTemplate.outerTextProvider = CLKSimpleTextProvider(text: temp(weather: weather))
            
            if let nextWeather = nextWeather {
                var down = false
                if nextWeather.tendancy == Tendency.minimum {
                    down = true
                } else if nextWeather.tendancy == Tendency.steady {
                    if nextWeather.night {
                        down = true
                    }
                }
                
                var min = 0
                var max = 0
                
                if down {
                    modularTemplate.leadingTextProvider = CLKSimpleTextProvider(text: temp(weather: nextWeather))
                    min = nextWeather.temperature
                    max = weather.temperature + 10
                } else {
                    modularTemplate.trailingTextProvider = CLKSimpleTextProvider(text: temp(weather: nextWeather))
                    min = weather.temperature - 10
                    max = nextWeather.temperature
                }
                
                var fraction = Float(weather.temperature - min) / Float(max - min)
                
                // protection
                if fraction > 1 {
                    fraction = Float(1)
                } else if fraction < 0 {
                    fraction = Float(0)
                }
                
                modularTemplate.gaugeProvider = CLKSimpleGaugeProvider(style: .ring, gaugeColor: ringColor(), fillFraction: fraction)
            }
        }
        
        return modularTemplate
    }
    
    func demoState() -> CLKComplicationTemplate {
        let modularTemplate = CLKComplicationTemplateGraphicCornerGaugeText()
        modularTemplate.outerTextProvider = CLKSimpleTextProvider(text: "25°")
        modularTemplate.leadingTextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.trailingTextProvider = CLKSimpleTextProvider(text: "30")
        modularTemplate.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: ringColor(), fillFraction: 0.6)
        
        return modularTemplate
    }
    
    func initialState() -> CLKComplicationTemplate {
        let modularTemplate = CLKComplicationTemplateGraphicCornerGaugeText()
        modularTemplate.outerTextProvider = CLKSimpleTextProvider(text: "--")
        modularTemplate.leadingTextProvider = CLKSimpleTextProvider(text:"")
        modularTemplate.trailingTextProvider = CLKSimpleTextProvider(text:"")
        modularTemplate.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: ringColor(), fillFraction: 0)
        
        return modularTemplate
    }
    
    func ringColor() -> UIColor {
        return UIColor(weatherColor:WeatherColor.watchRing)
    }
}
