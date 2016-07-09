//
//  ComplicationController.swift
//  temp Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    override init() {
        super.init()
    }
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([CLKComplicationTimeTravelDirections.None])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        var template:CLKComplicationTemplate? = nil
        
        if let city = PreferenceHelper.getSelectedCity() {
            let wrapper = SharedWeather.instance.wrapper
            
            if wrapper.weatherInformations.count > 0 {
                var weather:WeatherInformation? = nil
                if wrapper.weatherInformations[0].weatherDay == WeatherDay.Now {
                    weather = wrapper.weatherInformations[0]
                }
                
                var nextWeather:WeatherInformation? = nil
                if wrapper.weatherInformations.count > 1 {
                    nextWeather = wrapper.weatherInformations[1]
                }
                
                if complication.family == .ModularLarge {
                    template = generateLargeModularTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .ModularSmall {
                    template = generateSmallModularTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .CircularSmall {
                    template = generateSmallCircularTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .UtilitarianSmall {
                    template = generateSmallUtilitarianTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .UtilitarianLarge {
                    template = generateLargeUtilitarianTemplate(weather, nextWeather: nextWeather, city: city)
                }
            }
        } else {
            // empty city fallback
            if complication.family == .ModularLarge {
                template = generateEmptyLargeModularTemplate()
            } else if complication.family == .ModularSmall {
                template = generateEmptySmallModularTemplate()
            } else if complication.family == .CircularSmall {
                template = generateEmptySmallCircularTemplate()
            } else if complication.family == .UtilitarianSmall {
                template = generateEmptySmallUtilitarianTemplate()
            } else if complication.family == .UtilitarianLarge {
                template = generateEmptyLargeUtilitarianTemplate()
            }
        }
        
        if let template = template {
            let timelineEntry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template)
            handler(timelineEntry)
            return
        }
        
        handler(nil)
        
    }
    
    func generateLargeModularTemplate(weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateModularLargeTable {
        let modularTemplate = CLKComplicationTemplateModularLargeTable()
        modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: CityHelper.cityName(city))
        modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
        
        if let weather = weather {
            modularTemplate.headerImageProvider = CLKImageProvider(onePieceImage: weather.image())
            modularTemplate.row1Column1TextProvider = getCurrentTemperature(weather)
            modularTemplate.row2Column1TextProvider = getMinMaxTemperature(nextWeather)
        } else {
            modularTemplate.row1Column1TextProvider = getMinMaxTemperature(nextWeather)
            modularTemplate.row2Column1TextProvider = getCurrentTemperature(weather)
        }
        
        return modularTemplate
    }
    
    func generateEmptyLargeModularTemplate() -> CLKComplicationTemplateModularLargeTable {
        let modularTemplate = CLKComplicationTemplateModularLargeTable()
        modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "weatherlr")
        modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: "Open iPhone app Complication1".localized())
        modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: "Open iPhone app Complication2".localized())
        modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
        
        return modularTemplate
    }
    
    func generateSmallModularTemplate(weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateModularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
        modularTemplate.textProvider = getCurrentTemperature(weather)
        
        return modularTemplate
    }
    
    func generateEmptySmallModularTemplate() -> CLKComplicationTemplateModularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: "iPhone".localized())
        
        return modularTemplate
    }
    
    func generateSmallCircularTemplate(weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateCircularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
        modularTemplate.textProvider = getCurrentTemperature(weather)
        
        return modularTemplate
    }
    
    func generateEmptySmallCircularTemplate() -> CLKComplicationTemplateCircularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: "iPhone".localized())
        
        return modularTemplate
    }
    
    func generateSmallUtilitarianTemplate(weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
        modularTemplate.textProvider = getCurrentTemperature(weather)
        
        if let weather = weather {
            modularTemplate.imageProvider = CLKImageProvider(onePieceImage: weather.image())
        }
        
        return modularTemplate
    }
    
    func generateEmptySmallUtilitarianTemplate() -> CLKComplicationTemplateUtilitarianSmallFlat {
        let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: "iPhone".localized())
        
        return modularTemplate
    }
    
    func generateLargeUtilitarianTemplate(weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateUtilitarianLargeFlat {
        let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
        modularTemplate.textProvider = getCurrentTemperature(weather)
        
        if let weather = weather {
            modularTemplate.imageProvider = CLKImageProvider(onePieceImage: weather.image())
        }
        
        return modularTemplate
    }
    
    func generateEmptyLargeUtilitarianTemplate() -> CLKComplicationTemplateUtilitarianLargeFlat {
        let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: "iPhone".localized())
        
        return modularTemplate
    }
    
    func getCurrentTemperature(weather: WeatherInformation?) -> CLKSimpleTextProvider {
        if let weather = weather {
            let provider = CLKSimpleTextProvider(text: "Currently".localized() + " " + String(weather.temperature) + "°")
            provider.shortText = String(weather.temperature) + "°"
            return provider
        } else {
            return CLKSimpleTextProvider(text: "")
        }
    }
    
    func getMinMaxTemperature(nextWeather: WeatherInformation?) -> CLKSimpleTextProvider {
        if let nextWeather = nextWeather {
            let minMaxName = WeatherHelper.getMinMaxImageName(nextWeather)
            var minMaxLabel = "Minimum".localized()
            if minMaxName == "up" {
                minMaxLabel = "Maximum".localized()
            }
            let provider = CLKSimpleTextProvider(text: minMaxLabel + " " + String(nextWeather.temperature) + "°")
            provider.shortText = String(nextWeather.temperature) + "°"
            return provider
        }
        
        return CLKSimpleTextProvider(text: "")
    }
    
    func requestedUpdateDidBegin() {
        loadData()
    }
    
    
    func loadData() {
        if let city = PreferenceHelper.getSelectedCity() {
            SharedWeather.instance.getWeather(city, callback: {self.refresh()})
        }

    }
    
    func refresh() {
        let server=CLKComplicationServer.sharedInstance()
        
        for comp in (server.activeComplications)! {
            server.reloadTimelineForComplication(comp)
        }
    }

    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        handler(NSDate(timeIntervalSinceNow: 60*60))
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        var template: CLKComplicationTemplate? = nil
        
        switch complication.family {
        case .ModularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "0°")
            
            template = modularTemplate
            break;
        case .ModularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeTable()
            
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "weatherlr")
            modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: "")
            modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
            modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: "")
            modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
            
            template = modularTemplate
            break;
        case .UtilitarianSmall:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "0°")
            
            template = modularTemplate
            break;
        case .UtilitarianLarge:
            let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "0°")
            
            template = modularTemplate
            break;
        case .CircularSmall:
            let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "0°")
            
            template = modularTemplate
            break;
        }
        
        handler(template)
    }
    
}
