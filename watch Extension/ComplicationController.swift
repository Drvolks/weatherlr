//
//  ComplicationController.swift
//  temp Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import ClockKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource, WeatherUpdateDelegate {
    override init() {
        super.init()
        
        if let city = PreferenceHelper.getSelectedCity() {
            SharedWeather.instance.getWeather(city, delegate: self)
        }
    }
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Swift.Void) {
        handler(CLKComplicationTimeTravelDirections())
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Swift.Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Swift.Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Swift.Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Swift.Void) {
        
        print("complication getCurrentTimelineEntry")

        
        var template:CLKComplicationTemplate? = nil
        
        if let city = PreferenceHelper.getSelectedCity() {
            if InterfaceController.wrapper.weatherInformations.count > 0 {
                print("complication has weather info")
                
                var weather:WeatherInformation? = nil
                if InterfaceController.wrapper.weatherInformations[0].weatherDay == WeatherDay.now {
                    weather = InterfaceController.wrapper.weatherInformations[0]
                }
                
                var nextWeather:WeatherInformation? = nil
                if InterfaceController.wrapper.weatherInformations.count > 1 {
                    nextWeather = InterfaceController.wrapper.weatherInformations[1]
                }
                
                if complication.family == .modularLarge {
                    template = generateLargeModularTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .modularSmall {
                    template = generateSmallModularTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .circularSmall {
                    template = generateSmallCircularTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .utilitarianSmall {
                    template = generateSmallUtilitarianTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .utilitarianLarge {
                    template = generateLargeUtilitarianTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .extraLarge {
                    template = generateExtraLargeTemplate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .utilitarianSmallFlat {
                    template = generateSmallUtilitarianTemplate(weather, nextWeather: nextWeather, city: city)
                }
            }
        } else {
            // empty city fallback
            if complication.family == .modularLarge {
                template = generateEmptyLargeModularTemplate()
            } else if complication.family == .modularSmall {
                template = generateEmptySmallModularTemplate()
            } else if complication.family == .circularSmall {
                template = generateEmptySmallCircularTemplate()
            } else if complication.family == .utilitarianSmall {
                template = generateEmptySmallUtilitarianTemplate()
            } else if complication.family == .utilitarianLarge {
                template = generateEmptyLargeUtilitarianTemplate()
            } else if complication.family == .extraLarge {
                template = generateEmptyExtraLargeTemplate()
            } else if complication.family == .extraLarge {
                template = generateEmptySmallUtilitarianTemplate()
            }
        }
        
        if let template = template {
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
            return
        }
        
        handler(nil)
        
    }
    
    func generateLargeModularTemplate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateModularLargeTable {
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
    
    func generateSmallModularTemplate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateModularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
        modularTemplate.textProvider = getCurrentTemperature(weather)
        
        return modularTemplate
    }
    
    func generateExtraLargeTemplate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateExtraLargeColumnsText {
        let modularTemplate = CLKComplicationTemplateExtraLargeColumnsText()
        if let weather = weather {
            modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: String(weather.temperature) + "°")
        } else {
            modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: "")
        }
        modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
        
        return modularTemplate
    }
    
    func generateEmptyExtraLargeTemplate() -> CLKComplicationTemplateExtraLargeColumnsText {
        let modularTemplate = CLKComplicationTemplateExtraLargeColumnsText()
        modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: "iPhone".localized())
        modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
        
        return modularTemplate
    }
    
    func generateEmptySmallModularTemplate() -> CLKComplicationTemplateModularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: "iPhone".localized())
        
        return modularTemplate
    }
    
    func generateSmallCircularTemplate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateCircularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
        modularTemplate.textProvider = getCurrentTemperature(weather)
        
        return modularTemplate
    }
    
    func generateEmptySmallCircularTemplate() -> CLKComplicationTemplateCircularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: "iPhone".localized())
        
        return modularTemplate
    }
    
    func generateSmallUtilitarianTemplate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateUtilitarianSmallFlat {
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
    
    func generateLargeUtilitarianTemplate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateUtilitarianLargeFlat {
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
    
    func getCurrentTemperature(_ weather: WeatherInformation?) -> CLKSimpleTextProvider {
        if let weather = weather {
            let provider = CLKSimpleTextProvider(text: "Currently".localized() + " " + String(weather.temperature) + "°")
            provider.shortText = String(weather.temperature) + "°"
            return provider
        } else {
            return CLKSimpleTextProvider(text: "")
        }
    }
    
    func getMinMaxTemperature(_ nextWeather: WeatherInformation?) -> CLKSimpleTextProvider {
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

    
    func beforeUpdate() {
        // nothing to do
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Swift.Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Swift.Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
 
    // MARK: - Placeholder Templates
    // TODO fusion avec getLocalizableSampleTemplate?
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Swift.Void) {
        var template: CLKComplicationTemplate? = nil
        
        let image = CLKImageProvider(onePieceImage: UIImage(named: String(describing:WeatherStatus.sunny))!)

        let provideTemperature = CLKSimpleTextProvider(text: "Currently".localized() + " 25°")
        provideTemperature.shortText = "25°"
        
        let providerMax = CLKSimpleTextProvider(text: "Maximum".localized() + " 28°")
        providerMax.shortText = "28°"
        
        switch complication.family {
        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "0°")
            
            template = modularTemplate
            break
        case .modularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeTable()
            modularTemplate.headerImageProvider = image
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "weatherlr")
            modularTemplate.row1Column1TextProvider = provideTemperature
            modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
            modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: "")
            modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")
            
            template = modularTemplate
            break
        case .utilitarianSmall:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        case .utilitarianLarge:
            let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        case .circularSmall:
            let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        case .extraLarge:
            let modularTemplate = CLKComplicationTemplateExtraLargeColumnsText()
            modularTemplate.row1Column1TextProvider = provideTemperature
            break
        case .utilitarianSmallFlat:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        }
        
        handler(template)
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        var template: CLKComplicationTemplate? = nil
        
        let city = CLKSimpleTextProvider(text: "Montreal")
        
        let image = CLKImageProvider(onePieceImage: UIImage(named: String(describing:WeatherStatus.sunny))!)
        
        let provideTemperature = CLKSimpleTextProvider(text: "Currently".localized() + " 25°")
        provideTemperature.shortText = "25°"
        
        let providerMax = CLKSimpleTextProvider(text: "Maximum".localized() + " 28°")
        providerMax.shortText = "28°"
        
        switch complication.family {
        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        case .modularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeTable()
            
            modularTemplate.headerTextProvider = city
            modularTemplate.headerImageProvider = image
            modularTemplate.row1Column1TextProvider = provideTemperature
            modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "")
            modularTemplate.row2Column1TextProvider = providerMax
            modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "")

            
            template = modularTemplate
            break
        case .utilitarianSmall:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        case .utilitarianLarge:
            let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        case .circularSmall:
            let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        case .extraLarge:
            let modularTemplate = CLKComplicationTemplateExtraLargeColumnsText()
            modularTemplate.row1Column1TextProvider = provideTemperature
            break
        case .utilitarianSmallFlat:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        }
        
        handler(template)
    }
    
    func weatherDidUpdate(_ wrapper: WeatherInformationWrapper) {
        InterfaceController.wrapper = wrapper
        
        updateComplication()
    }
    
    func weatherShouldUpdate() {}
    
    func updateComplication() {
        let complicationServer = CLKComplicationServer.sharedInstance()
        if let complications = complicationServer.activeComplications {
            for complication in complications {
                print("updating complication", complication)
                
                complicationServer.reloadTimeline(for: complication)
            }
        }
    }
}
