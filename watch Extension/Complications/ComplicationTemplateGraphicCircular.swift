//
//  ComplicationTemplateGraphicCircular.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2018-10-04.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit
import WeatherFramework
import ClockKit

class ComplicationTemplateGraphicCircular: ComplicationTemplate, ComplicationTemplateProtocol {
    func generate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city: City) -> CLKComplicationTemplate {
        let modularTemplate = initialState() as! CLKComplicationTemplateGraphicCircularOpenGaugeRangeText
        
        if let weather = weather {
            if let nextWeather = nextWeather {
                let down = isDown(nextWeather)
            
                if(down) {
                    modularTemplate.leadingTextProvider = CLKSimpleTextProvider(text: temp(nextWeather))
                } else {
                    modularTemplate.trailingTextProvider = CLKSimpleTextProvider(text: temp(nextWeather))
                }
                
                let fraction = gaugeFraction(down: down, weather: weather, nextWeather: nextWeather)
                modularTemplate.gaugeProvider = CLKSimpleGaugeProvider(style: .ring, gaugeColor: ringColor(), fillFraction: fraction)
            }
            
            modularTemplate.centerTextProvider = CLKSimpleTextProvider(text: temp(weather))
        }
        
        return modularTemplate
    }
    
    func demoState() -> CLKComplicationTemplate {
        let modularTemplate = CLKComplicationTemplateGraphicCircularOpenGaugeRangeText()
        modularTemplate.centerTextProvider = CLKSimpleTextProvider(text: "25°")
        modularTemplate.leadingTextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.trailingTextProvider = CLKSimpleTextProvider(text: "30")
        modularTemplate.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: ringColor(), fillFraction: 0.6)
        return modularTemplate
    }
    
    func initialState() -> CLKComplicationTemplate {
        let modularTemplate = CLKComplicationTemplateGraphicCircularOpenGaugeRangeText()
        modularTemplate.centerTextProvider = CLKSimpleTextProvider(text: "--")
        modularTemplate.leadingTextProvider = CLKSimpleTextProvider(text:"")
        modularTemplate.trailingTextProvider = CLKSimpleTextProvider(text:"")
        modularTemplate.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: ringColor(), fillFraction: 0)
        return modularTemplate
    }
}
