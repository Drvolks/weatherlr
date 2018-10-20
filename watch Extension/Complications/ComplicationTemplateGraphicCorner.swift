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
            modularTemplate.outerTextProvider = CLKSimpleTextProvider(text: temp(weather))
            
            if let nextWeather = nextWeather {
                let down = isDown(nextWeather)

                if down {
                    modularTemplate.leadingTextProvider = CLKSimpleTextProvider(text: temp(nextWeather))
                } else {
                    modularTemplate.trailingTextProvider = CLKSimpleTextProvider(text: temp(nextWeather))
                }
                
                let fraction = gaugeFraction(down: down, weather: weather, nextWeather: nextWeather)
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
}
