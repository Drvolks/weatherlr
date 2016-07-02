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
        handler([.Forward, .Backward])
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
                let weatherInformationWrapper = WeatherHelper.getWeatherInformations(city)
                
                if weatherInformationWrapper.weatherInformations.count > 0 {
                    let modularTemplate = CLKComplicationTemplateModularLargeTable()
                    
                    let weather = weatherInformationWrapper.weatherInformations[0]
                    
                    var name = city.englishName
                    if PreferenceHelper.isFrench() {
                        name = city.frenchName
                    }
                    modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: name)
                    modularTemplate.headerImageProvider = CLKImageProvider(onePieceImage: weather.image())
                    modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: String(weather.temperature))
                    modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
                    modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: "")
                    modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
                    
                    let timelineEntry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: modularTemplate)
                    
                    handler(timelineEntry)
                    return
                }
            }
        }
        
            handler(nil)
        
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
