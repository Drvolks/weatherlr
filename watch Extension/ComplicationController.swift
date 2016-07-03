//
//  ComplicationController.swift
//  temp Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    var weatherInformationWrapper:WeatherInformationWrapper?
    
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
        if let wrapper = weatherInformationWrapper, let city = PreferenceHelper.getSelectedCity() {
            if wrapper.weatherInformations.count > 0 {
                let weather = wrapper.weatherInformations[0]
                var nextWeather:WeatherInformation? = nil
                if wrapper.weatherInformations.count > 1 {
                    nextWeather = wrapper.weatherInformations[1]
                }
                
                var template:CLKComplicationTemplate? = nil
                if complication.family == .ModularLarge {
                    template = self.generateLargeModularTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .ModularSmall {
                    template = self.generateSmallModularTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .CircularSmall {
                    template = self.generateSmallCircularTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .UtilitarianSmall {
                    template = self.generateSmallUtilitarianTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .UtilitarianLarge {
                    template = self.generateLargeUtilitarianTemplate(weather, nextWeather: nextWeather, city: city)
                }
                
                if let template = template {
                    let timelineEntry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template)
                    handler(timelineEntry)
                    return
                }
            }
        }
        
        handler(nil)
        
    }
    
    func generateLargeModularTemplate(weather: WeatherInformation, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateModularLargeTable {
        let modularTemplate = CLKComplicationTemplateModularLargeTable()
        modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: getCityName(city))
        modularTemplate.headerImageProvider = CLKImageProvider(onePieceImage: weather.image())
        modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: getCurrentTemperature(weather))
        modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: getMinMaxTemperature(weather, nextWeather: nextWeather))
        modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
        
        return modularTemplate
    }
    
    func generateSmallModularTemplate(weather: WeatherInformation, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateModularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: String(weather.temperature) + "°")
        
        return modularTemplate
    }
    
    func generateSmallCircularTemplate(weather: WeatherInformation, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateCircularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: String(weather.temperature) + "°")
        
        return modularTemplate
    }
    
    func generateSmallUtilitarianTemplate(weather: WeatherInformation, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: String(weather.temperature) + "°")
        modularTemplate.imageProvider = CLKImageProvider(onePieceImage: weather.image())
        
        return modularTemplate
    }
    
    func generateLargeUtilitarianTemplate(weather: WeatherInformation, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateUtilitarianLargeFlat {
        let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: String(weather.temperature) + "°")
        modularTemplate.imageProvider = CLKImageProvider(onePieceImage: weather.image())
        
        return modularTemplate
    }
    
    func getCurrentTemperature(weather: WeatherInformation) -> String {
        return "Currently".localized() + " " + String(weather.temperature) + "°"
    }
    
    func getCityName(city: City) -> String {
        var name = city.englishName
        if PreferenceHelper.isFrench() {
            name = city.frenchName
        }
        
        return name
    }
    
    func getMinMaxTemperature(weather: WeatherInformation, nextWeather: WeatherInformation?) -> String {
        var minMaxTemperature = ""
        if let nextWeather = nextWeather {
            let minMaxName = WeatherHelper.getMinMaxImageName(weather)
            var minMaxLabel = "Minimum".localized()
            if minMaxName == "up" {
                minMaxLabel = "Maximum".localized()
            }
            minMaxTemperature = minMaxLabel + " " + String(nextWeather.temperature) + "°"
        }
        
        return minMaxTemperature
    }
    
    func requestedUpdateDidBegin() {
        loadData()
    }
    
    
    func loadData() {
        weatherInformationWrapper = nil
        
        if let city = PreferenceHelper.getSelectedCity() {
            let url = UrlHelper.getUrl(city)
            
            if let url = NSURL(string: url) {
                let task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
                    dispatch_async(dispatch_get_main_queue(), {
                        if (data != nil && error == nil) {
                            let rssParser = RssParser(xmlData: data!, language: PreferenceHelper.getLanguage())
                            self.weatherInformationWrapper = WeatherHelper.generateWeatherInformation(rssParser)
                            
                            let server=CLKComplicationServer.sharedInstance()
                            
                            for comp in (server.activeComplications)! {
                                server.reloadTimelineForComplication(comp)
                            }
                        }
                    })
                }
                task.resume()
                return
            }
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
            break;
        case .ModularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeTable()
            
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "weatherlr")
            modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: "Loading".localized())
            modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
            modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: "")
            modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
            
            
            template = modularTemplate
            break;
        case .UtilitarianSmall:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "0°")
            break;
        case .UtilitarianLarge:
            let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "0°")
            break;
        case .CircularSmall:
            let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "0°")
            break;
        }
        
        handler(template)
    }
    
}
