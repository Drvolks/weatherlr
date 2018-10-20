//
//  WatchTemplate.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2018-10-04.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit

protocol ComplicationTemplateProtocol {
    func generate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplate
    func initialState() -> CLKComplicationTemplate
    func demoState() -> CLKComplicationTemplate
}

open class ComplicationTemplate {
    func temp(_ weather: WeatherInformation) -> String {
        return String(weather.temperature) + "°"
    }
    
    func isDown(_ nextWeather:WeatherInformation) -> Bool {
        var down = false
        if nextWeather.tendancy == Tendency.minimum {
            down = true
        } else if nextWeather.tendancy == Tendency.steady {
            if nextWeather.night {
                down = true
            }
        }
        
        return down
    }
    
    func gaugeFraction(down: Bool, weather: WeatherInformation, nextWeather: WeatherInformation) -> Float {
        var min = 0
        var max = 0
        
        if down {
            min = nextWeather.temperature
            max = weather.temperature + 10
        } else {
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
        
        return fraction
    }
    
    func ringColor() -> UIColor {
        return UIColor(weatherColor:WeatherColor.watchRing)
    }
}
