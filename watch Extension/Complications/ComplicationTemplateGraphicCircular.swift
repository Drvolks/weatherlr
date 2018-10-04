//
//  ComplicationTemplateGraphicCircular.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2018-10-04.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit

class ComplicationTemplateGraphicCircular: ComplicationTemplate, ComplicationTemplateProtocol {
    func generate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city: City) -> CLKComplicationTemplate {
        let modularTemplate = initialState() as! CLKComplicationTemplateGraphicCircularImage
        
        if let weather = weather {
            modularTemplate.imageProvider = WatchImageHelper.getImageProviderFull(weatherInformation: weather)
            
        }
        
        return modularTemplate
    }
    
    func initialState() -> CLKComplicationTemplate {
        let modularTemplate = CLKComplicationTemplateGraphicCircularImage()
        // TODO avoir une image plus générique
        modularTemplate.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "ComplicationSunny")!)
        return modularTemplate
    }
    
    func demoState() -> CLKComplicationTemplate {
        let modularTemplate = CLKComplicationTemplateGraphicCircularImage()
        modularTemplate.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "ComplicationSunny")!)
        return modularTemplate
    }
}
