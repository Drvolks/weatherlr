//
//  ComplicationController.swift
//  temp Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import ClockKit
import WatchKit
import WeatherFramework

class ComplicationController: NSObject, CLKComplicationDataSource, URLSessionDelegate, URLSessionDownloadDelegate {
    override init() {
        super.init()
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
        let wrapper = ExtensionDelegateHelper.getWrapper()
  
        #if DEBUG
            print("Complication - getCurrentTimelineEntry")
        #endif

        var template:CLKComplicationTemplate? = nil
        
        let city = PreferenceHelper.getCityToUse()
        if !LocationServices.isUseCurrentLocation(city) {
            if(wrapper.refreshNeeded()) {
                #if DEBUG
                    print("Complication - refresh needed")
                #endif
            
                ExtensionDelegateHelper.launchURLSessionNow(self)
            }
        
            if wrapper.weatherInformations.count > 0 {
                var weather:WeatherInformation? = nil
                if wrapper.weatherInformations[0].weatherDay == WeatherDay.now {
                    weather = wrapper.weatherInformations[0]
                }
                
                var nextWeather:WeatherInformation? = nil
                if wrapper.weatherInformations.count > 1 {
                    nextWeather = wrapper.weatherInformations[1]
                }
                
                if complication.family == .modularLarge {
                    template = generateLargeModularTemplate(weather, nextWeather: nextWeather, city: city, wrapper: wrapper)
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
                } else if complication.family == .graphicCorner {
                    template = ComplicationTemplateGraphicCorner().generate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .graphicCircular {
                    template = ComplicationTemplateGraphicCircular().generate(weather, nextWeather: nextWeather, city: city)
                } else if complication.family == .graphicRectangular {
                    template = generateGraphicRectangular(weather, nextWeather: nextWeather, city: city, wrapper: wrapper)
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
            } else if complication.family == .graphicCorner {
                template = ComplicationTemplateGraphicCorner().initialState()
            } else if complication.family == .graphicCircular {
                template = ComplicationTemplateGraphicCircular().initialState()
            } else if complication.family == .graphicRectangular {
                template = generateEmptyGraphicRectangular()
            }
        }
        
        if let template = template {
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
            return
        }
        
        handler(nil)
        
    }
    
    func generateLargeModularTemplate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City, wrapper: WeatherInformationWrapper) -> CLKComplicationTemplateModularLargeStandardBody {
        let modularTemplate = CLKComplicationTemplateModularLargeStandardBody()
        var cityName = CityHelper.cityName(city)
        
        if LocationServices.isUseCurrentLocation(PreferenceHelper.getSelectedCity()) {
            cityName = "➤ " + cityName
        }
        
        modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: cityName)
        
        if let weather = weather {
            let lang = PreferenceHelper.getLanguage()
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: String(describing: lang))
            dateFormatter.timeStyle = .short
            let ladate = dateFormatter.string(from: wrapper.lastRefresh as Date)

            modularTemplate.headerImageProvider = WatchImageHelper.getImage(weatherInformation: weather)
            modularTemplate.body1TextProvider = getCurrentTemperature(weather, showCurrently: true)

            modularTemplate.body2TextProvider =  getMinMaxTemperature(nextWeather, wrapper: wrapper, ladate:ladate)
            
            
            
            // TODO getMinMaxTemperature(weather, wrapper: wrapper)
        } else if let weather = nextWeather {
            modularTemplate.body1TextProvider = getMinMaxTemperature(weather, wrapper: wrapper, ladate: "")
            modularTemplate.body2TextProvider = CLKSimpleTextProvider(text: "")
        } else {
            modularTemplate.body1TextProvider = CLKSimpleTextProvider(text: "")
            modularTemplate.body2TextProvider = CLKSimpleTextProvider(text: "")
        }
        
        return modularTemplate
    }
    
    func generateEmptyLargeModularTemplate() -> CLKComplicationTemplateModularLargeStandardBody {
        let modularTemplate = CLKComplicationTemplateModularLargeStandardBody()
        modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "weatherlr")
        modularTemplate.body1TextProvider = CLKSimpleTextProvider(text: "Open iPhone app Complication1".localized())
        modularTemplate.body2TextProvider = CLKSimpleTextProvider(text: "Open iPhone app Complication2".localized())

        return modularTemplate
    }
    
    func generateSmallModularTemplate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateModularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
        modularTemplate.textProvider = getCurrentTemperature(weather, showCurrently: true)
        
        return modularTemplate
    }
    
    func generateExtraLargeTemplate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateExtraLargeStackImage {
        let modularTemplate = CLKComplicationTemplateExtraLargeStackImage()
        
        if let weather = weather {
            modularTemplate.line1ImageProvider = WatchImageHelper.getImage(weatherInformation: weather)
            modularTemplate.line2TextProvider = getCurrentTemperature(weather, showCurrently: false)
        }
        
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
        modularTemplate.textProvider = getCurrentTemperature(weather, showCurrently: true)
        
        return modularTemplate
    }
    
    func generateEmptySmallCircularTemplate() -> CLKComplicationTemplateCircularSmallSimpleText {
        let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: "iPhone".localized())
        
        return modularTemplate
    }
    
    func generateSmallUtilitarianTemplate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
        modularTemplate.textProvider = getCurrentTemperature(weather, showCurrently: true)
        
        if let weather = weather {
            modularTemplate.imageProvider = WatchImageHelper.getImage(weatherInformation: weather)
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
        modularTemplate.textProvider = getCurrentTemperature(weather, showCurrently: true)
        
        if let weather = weather {
            modularTemplate.imageProvider = WatchImageHelper.getImage(weatherInformation: weather)
        }
        
        return modularTemplate
    }
    
    func generateEmptyLargeUtilitarianTemplate() -> CLKComplicationTemplateUtilitarianLargeFlat {
        let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
        modularTemplate.textProvider = CLKSimpleTextProvider(text: "iPhone".localized())
        
        return modularTemplate
    }
    
    func getCurrentTemperature(_ weather: WeatherInformation?, showCurrently: Bool) -> CLKSimpleTextProvider {
        if let weather = weather {
            var text = String(weather.temperature) + "°"
            if(showCurrently) {
                text = "Currently".localized() + " " + text
            }
            let provider = CLKSimpleTextProvider(text: text)
            provider.shortText = String(weather.temperature) + "°"
            return provider
        } else {
            return CLKSimpleTextProvider(text: "")
        }
    }
    
    func getMinMaxTemperature(_ nextWeather: WeatherInformation?, wrapper:WeatherInformationWrapper, ladate:String) -> CLKSimpleTextProvider {
        var warning = "";
        if(wrapper.expiredTooLongAgo()) {
            warning = " ⚠️";
        }
        
        if let nextWeather = nextWeather {
            let minMaxName = WeatherHelper.getMinMaxImageName(nextWeather)
            var minMaxLabel = "Minimum".localized()
            if minMaxName == "up" {
                minMaxLabel = "Maximum".localized()
            }
            var miniMinMaxLabel = "Min".localized()
            if minMaxName == "up" {
                miniMinMaxLabel = "Max".localized()
            }
            
            let provider = CLKSimpleTextProvider(text: minMaxLabel + " " + String(nextWeather.temperature) + "°" + warning)
            provider.shortText = miniMinMaxLabel + " " + String(nextWeather.temperature) + "°" + warning
            return provider
        }
        
        return CLKSimpleTextProvider(text: "")
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
        let imageFull = CLKFullColorImageProvider(fullColorImage: UIImage(named: String(describing:WeatherStatus.sunny))!)

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
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "Montréal")
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
            let modularTemplate = CLKComplicationTemplateExtraLargeStackImage()
            modularTemplate.line1ImageProvider = image
            modularTemplate.line2TextProvider = CLKSimpleTextProvider(text: "25°")
            
            template = modularTemplate
            break
        case .utilitarianSmallFlat:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        case .graphicCorner:
            template = ComplicationTemplateGraphicCorner().demoState()
            break
        case .graphicBezel:
            // TODO
            break
        case .graphicCircular:
            template = ComplicationTemplateGraphicCircular().demoState()
            break
        case .graphicRectangular:
            let modularTemplate = CLKComplicationTemplateGraphicRectangularStandardBody()
            
            modularTemplate.headerImageProvider = imageFull
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "weatherlr")
            modularTemplate.body1TextProvider = provideTemperature
            modularTemplate.body1TextProvider = providerMax
            
            template = modularTemplate
            break
        @unknown default:
            print("Unknown family")
            break
        }
        
        handler(template)
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        var template: CLKComplicationTemplate? = nil
        
        let city = CLKSimpleTextProvider(text: "Montreal")
        
        let image = CLKImageProvider(onePieceImage: UIImage(named: String(describing:WeatherStatus.sunny))!)
        let imageFull = CLKFullColorImageProvider(fullColorImage: UIImage(named: String(describing:WeatherStatus.sunny))!)
        
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
            let modularTemplate = CLKComplicationTemplateExtraLargeStackImage()
            modularTemplate.line1ImageProvider = image
            modularTemplate.line2TextProvider = CLKSimpleTextProvider(text: "25°")
            
            template = modularTemplate
            break
        case .utilitarianSmallFlat:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            modularTemplate.textProvider = provideTemperature
            
            template = modularTemplate
            break
        case .graphicCorner:
            template = ComplicationTemplateGraphicCorner().initialState()
            break
        case .graphicBezel:
            // TODO
            break
        case .graphicCircular:
            template = ComplicationTemplateGraphicCircular().initialState()
            break
        case .graphicRectangular:
            let modularTemplate = CLKComplicationTemplateGraphicRectangularStandardBody()
            
            modularTemplate.headerImageProvider = imageFull
            modularTemplate.headerTextProvider = city
            modularTemplate.body1TextProvider = provideTemperature
            modularTemplate.body1TextProvider = providerMax
            
            template = modularTemplate
            break
        @unknown default:
            print("Unknown family")
            break
        }
        
        handler(template)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        #if DEBUG
            print("Watch complication urlSession didFinishDownloadingTo")
        #endif
        
        let city = PreferenceHelper.getCityToUse()
        if !LocationServices.isUseCurrentLocation(city) {
            do {
                let xmlData = try Data(contentsOf: location)
                ExtensionDelegateHelper.setWrapper(WeatherHelper.getWeatherInformationsNoCache(xmlData, city: city))
                
                #if DEBUG
                    print("Watch complication wrapper updated")
                #endif
                
                ExtensionDelegateHelper.updateComplication()
            } catch {
                print("Error info: \(error)")
                
                // plan b
                ExtensionDelegateHelper.launchURLSessionNow(self)
            }
        } else {
            #if DEBUG
                print("Watch complication urlSession didFinishDownloadingTo - no selected city")
            #endif
        }
        
        ExtensionDelegateHelper.scheduleRefresh(Constants.backgroundRefreshInSeconds)
    }
    
    func cityHasBeenUpdated(_ city: City) {
        ExtensionDelegateHelper.launchURLSessionNow(self)
    }
    
    func getAllCityList() -> [City] {
        NSKeyedUnarchiver.setClass(City.self, forClassName: "weatherlr.City")
        return CityHelper.loadAllCities()
    }
    
    func generateEmptyGraphicRectangular() -> CLKComplicationTemplateGraphicRectangularStandardBody {
        let modularTemplate = CLKComplicationTemplateGraphicRectangularStandardBody()
        
        modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.body1TextProvider = CLKSimpleTextProvider(text: "")
        modularTemplate.body2TextProvider = CLKSimpleTextProvider(text: "")
        
        return modularTemplate
    }
    
    func generateGraphicRectangular(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City, wrapper:WeatherInformationWrapper) -> CLKComplicationTemplateGraphicRectangularStandardBody {
        let modularTemplate = CLKComplicationTemplateGraphicRectangularStandardBody()
        var cityName = CityHelper.cityName(city)
        
        if LocationServices.isUseCurrentLocation(PreferenceHelper.getSelectedCity()) {
            cityName = "➤ " + cityName
        }
        
        modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: cityName)
        
        if let weather = weather {
            let lang = PreferenceHelper.getLanguage()
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: String(describing: lang))
            dateFormatter.timeStyle = .short
            let ladate = dateFormatter.string(from: wrapper.lastRefresh as Date)
            
            modularTemplate.headerImageProvider = WatchImageHelper.getImageProviderFull(weatherInformation: weather)
            modularTemplate.body1TextProvider = getCurrentTemperature(weather, showCurrently: true)
            
            modularTemplate.body2TextProvider =  getMinMaxTemperature(nextWeather, wrapper: wrapper, ladate:ladate)
        } else if let weather = nextWeather {
            modularTemplate.body1TextProvider = getMinMaxTemperature(weather, wrapper: wrapper, ladate: "")
            modularTemplate.body2TextProvider = CLKSimpleTextProvider(text: "")
        } else {
            modularTemplate.body1TextProvider = CLKSimpleTextProvider(text: "")
            modularTemplate.body2TextProvider = CLKSimpleTextProvider(text: "")
        }
        
        return modularTemplate
    }
}
