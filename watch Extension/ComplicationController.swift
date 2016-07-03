//
//  ComplicationController.swift
//  temp Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
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
        if complication.family == .ModularLarge {
            if let city = PreferenceHelper.getSelectedCity() {
                let url = UrlHelper.getUrl(city)
                
                if let url = NSURL(string: url) {
                    let task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
                        dispatch_async(dispatch_get_main_queue(), {
                            if (data != nil && error == nil) {
                                let rssParser = RssParser(xmlData: data!, language: PreferenceHelper.getLanguage())
                                let weatherInformationWrapper = WeatherHelper.generateWeatherInformation(rssParser)
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    if weatherInformationWrapper.weatherInformations.count > 0 {
                                        let weather = weatherInformationWrapper.weatherInformations[0]
                                        var nextWeather:WeatherInformation? = nil
                                        if weatherInformationWrapper.weatherInformations.count > 1 {
                                            nextWeather = weatherInformationWrapper.weatherInformations[1]
                                        }
                                        
                                        let modularTemplate = self.generateLargeModularTemplate(weather, nextWeather: nextWeather, city: city)
                                        
                                        let timelineEntry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: modularTemplate)
                                        
                                        handler(timelineEntry)
                                    }
                                }
                            }
                        })
                    }
                    task.resume()
                    return
                }
            }
        }
        
        handler(nil)
        
    }
    
    func generateLargeModularTemplate(weather: WeatherInformation, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateModularLargeTable {
        var name = city.englishName
        if PreferenceHelper.isFrench() {
            name = city.frenchName
        }
        
        let currentTemperature = "Currently".localized() + " " + String(weather.temperature) + "°"
        
        var minMaxTemperature = ""
        if let nextWeather = nextWeather {
            let minMaxName = WeatherHelper.getMinMaxImageName(weather)
            var minMaxLabel = "Minimum".localized()
            if minMaxName == "up" {
                minMaxLabel = "Maximum".localized()
            }
            minMaxTemperature = minMaxLabel + " " + String(nextWeather.temperature) + "°"
        }
        
        let modularTemplate = CLKComplicationTemplateModularLargeTable()
        modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: name)
        modularTemplate.headerImageProvider = CLKImageProvider(onePieceImage: weather.image())
        modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: currentTemperature)
        modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: minMaxTemperature)
        modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
    
        
        return modularTemplate
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
        handler(NSDate(timeIntervalSinceNow: 60*30))
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        var template: CLKComplicationTemplate? = nil
        
        switch complication.family {
        case .ModularSmall:
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
            break;
        case .UtilitarianLarge:
            break;
        case .CircularSmall:
            break;
        }
        
        handler(template)
    }
    
}
