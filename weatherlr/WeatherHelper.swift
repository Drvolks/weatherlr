//
//  CityHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-23.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherHelper {
    static func getWeatherInformations(city:City) -> WeatherInformationWrapper {
        let cache = ExpiringCache.instance
        let cachedWeather = cache.objectForKey(city.id) as? WeatherInformationWrapper
        
        if cachedWeather != nil {
            return cachedWeather!
        }
        
        let weatherInformationWrapper = getWeatherInformationsNoCache(city)
        cache.setObject(weatherInformationWrapper, forKey: city.id)
        
        return weatherInformationWrapper
    }
    
    static func getWeatherInformationsNoCache(city:City) -> WeatherInformationWrapper {
        
        let url = UrlHelper.getUrl(city)
        
        if let url = NSURL(string: url) {
            if let rssParser = RssParser(url: url, language: PreferenceHelper.getLanguage()) {
                return generateWeatherInformation(rssParser)
            }
        }
        
        return WeatherInformationWrapper()
    }
    
    static func generateWeatherInformation(rssParser: RssParser) -> WeatherInformationWrapper {
        let rssEntries = rssParser.parse()
        let weatherInformationProcess = RssEntryToWeatherInformation(rssEntries: rssEntries)
        let weatherInformations = weatherInformationProcess.perform()
        let alerts = weatherInformationProcess.getAlerts()
        
        let weatherInformationWrapper = WeatherInformationWrapper(weatherInformations: weatherInformations, alerts: alerts)
        return weatherInformationWrapper
    }
    
    static func getOfflineWeather() -> WeatherInformationWrapper {
        let path = NSBundle.mainBundle().pathForResource("nu-29_English", ofType: "xml")
        let url = NSURL(fileURLWithPath: path!)
        
        if let rssParser = RssParser(url: url, language: PreferenceHelper.getLanguage()) {
            let rssEntries = rssParser.parse()
            let weatherInformationProcess = RssEntryToWeatherInformation(rssEntries: rssEntries)
            let weatherInformations = weatherInformationProcess.perform()
            let alerts = weatherInformationProcess.getAlerts()
            
            let weatherInformationWrapper = WeatherInformationWrapper(weatherInformations: weatherInformations, alerts: alerts)
            return weatherInformationWrapper
        }
        
        return WeatherInformationWrapper()
    }
    
    static func getImageSubstitute(weatherStatus: WeatherStatus) -> WeatherStatus? {
        switch(weatherStatus) {
        case .MainlyClear:
            return WeatherStatus.MainlySunny
        case .AFewFlurries,
             .LightSnowshower,
             .PeriodsOfLightSnow,
             .PeriodsOfSnow:
            return WeatherStatus.LightSnow
        case .AFewShowers,
             .LightRainshower,
             .PeriodsOfRain,
             .Showers,
             .ChanceOfRain,
             .Precipitation:
            return WeatherStatus.LightRain
        case .AMixOfSunAndCloud,
             .CloudyPeriods,
             .PartlyCloudy:
            return WeatherStatus.AFewClouds
        case .ChanceOfFlurries,
             .ChanceOfLightSnow,
             .CloudyWithXPercentChanceOfFlurries:
            return WeatherStatus.ChanceOfSnow
        case .ChanceOfRainShowersOrFlurries,
             .PeriodsOfLightSnowMixedWithRain,
             .ChanceOfSnowMixedWithRain,
             .ChanceOfSnowOrRain:
            return WeatherStatus.AFewRainShowersOrFlurries
        case .RainOrFreezingRain:
            return WeatherStatus.PeriodsOfRainOrFreezingRain
        case .ChanceOfShowersOrDrizzle,
             .ShowersOrDrizzle,
             .RainOrDrizzle,
             .PeriodsOfDrizzleOrRain,
             .PeriodsOfDrizzleMixedWithRain,
             .ChanceOfDrizzleOrRain,
             .DrizzleOrRain,
             .RainAtTimesHeavyOrDrizzle,
             .AFewShowersOrDrizzle,
             .ChanceOfRainOrDrizzle:
            return WeatherStatus.PeriodsOfRainOrDrizzle
        case .FreezingDrizzleOrRain:
            return WeatherStatus.PeriodsOfFreezingDrizzleOrRain
        case .DrizzleMixedWithFreezingDrizzle,
             .FreezingDrizzleOrDrizzle,
             .PeriodsOfDrizzleMixedWithFreezingDrizzle,
             .PeriodsOfFreezingDrizzleOrDrizzle,
             .PeriodsOfDrizzleOrFreezingDrizzle:
            return WeatherStatus.ChanceOfDrizzleMixedWithFreezingDrizzle
        case .Flurries:
            return WeatherStatus.Snow
        case .FlurriesAtTimesHeavy:
            return WeatherStatus.SnowAtTimesHeavy
        case .FlurriesOrRainShowers,
             .PeriodsOfRainMixedWithSnow,
             .PeriodsOfSnowOrRain,
             .RainShowersOrFlurries,
             .SnowMixedWithRain,
             .SnowOrRain,
             .SnowAtTimesHeavyMixedWithRain,
             .PeriodsOfSnowMixedWithRain,
             .RainMixedWithSnow,
             .LightSnowMixedWithRain,
             .LightSnowOrRain,
             .RainAtTimesHeavyOrSnow,
             .SnowAtTimesHeavyOrRain:
            return WeatherStatus.PeriodsOfRainOrSnow
        case .FreezingRainOrSnow,
             .PeriodsOfSnowMixedWithFreezingRain,
             .PeriodsOfFreezingRainOrSnow,
             .FreezingRainMixedWithSnow,
             .SnowOrFreezingRain,
             .LightSnowOrFreezingRain:
            return WeatherStatus.PeriodsOfLightSnowOrFreezingRain
        case .PeriodsOfLightSnowMixedWithFreezingDrizzle,
             .PeriodsOfSnowOrFreezingDrizzle,
             .PeriodsOfSnowMixedWithFreezingDrizzle:
            return WeatherStatus.SnowMixedWithFreezingDrizzle
        case .IncreasingCloudiness:
            return WeatherStatus.Clearing
        case .Overcast:
            return WeatherStatus.Cloudy
        case .PeriodsOfDrizzle:
            return WeatherStatus.ChanceOfDrizzle
        case .SnowAndBlowingSnow:
            return WeatherStatus.LightSnowAndBlowingSnow
        case .WetFlurries:
            return WeatherStatus.WetSnow
        case .Fog,
             .Haze,
             .FogPatches,
             .FogDissipating:
            return WeatherStatus.Mist
        case .PeriodsOfFreezingDrizzle,
             .ChanceOfFreezingDrizzle:
            return WeatherStatus.LightFreezingDrizzle
        case .PeriodsOfFreezingRainMixedWithIcePellets:
            return WeatherStatus.FreezingRainMixedWithIcePellets
        case .ChanceOfWetFlurriesOrRainShowers,
             .PeriodsOfWetSnowOrRain,
             .WetFlurriesOrRainShowers:
            return WeatherStatus.ChanceOfRainShowersOrWetFlurries
        case .LightWetSnow:
            return WeatherStatus.ChanceOfWetFlurries
        case .HeavyRainshower,
             .ChanceOfShowersAtTimesHeavy,
             .ShowersAtTimesHeavy:
            return WeatherStatus.RainAtTimesHeavy
        case .AFewShowersOrThunderstorms,
             .Thunderstorm,
             .ThunderstormWithLightRainshowers,
             .ShowersOrThunderstorms,
             .ThunderstormWithLightRain,
             .ChanceOfThunderstorms,
             .ShowersAtTimesHeavyOrThundershowers:
            return WeatherStatus.ChanceOfShowersOrThunderstorms
        case .SnowOrIcePellets,
             .IcePelletsOrSnow:
            return WeatherStatus.SnowMixedWithIcePellets
        default:
            return nil
        }
    }
    
    static func getMinMaxImage(weatherInfo: WeatherInformation, header: Bool) -> UIImage {
        let name = getMinMaxImageName(weatherInfo)
        
        if header {
            return UIImage(named: name + "Header")!
        } else {
            return UIImage(named: name)!
        }
    }
    
    static func getMinMaxImageName(weatherInfo: WeatherInformation) -> String {
        var name = "up"
        
        if weatherInfo.tendancy == Tendency.Minimum {
            name = "down"
        } else if weatherInfo.tendancy == Tendency.Steady {
            if weatherInfo.night {
                name = "down"
            }
        }
        
        return name
    }
    
    static func getIndexAjust(weatherInformations:[WeatherInformation]) -> Int {
        var indexAjust = 1
        
        if weatherInformations.count == 0 {
            return indexAjust
        }
        
        let weatherInfoBase = weatherInformations[0]
        if weatherInfoBase.weatherDay != WeatherDay.Now {
            indexAjust = 0
        }
        
        return indexAjust
    }
    
    static func getWeatherDayWhenText(weatherInfo: WeatherInformation) -> String {
        if weatherInfo.weatherDay == WeatherDay.Today {
            if weatherInfo.night {
                return weatherInfo.when
            } else {
                return "Today".localized()
            }
        } else {
            if weatherInfo.night {
                return weatherInfo.when
            } else {
                let today = NSDate()
                let theDate = addDaystoGivenDate(today, NumberOfDaysToAdd: weatherInfo.weatherDay.rawValue)
                let dateFormatter = NSDateFormatter()
                let lang = PreferenceHelper.getLanguage()
                dateFormatter.locale = NSLocale(localeIdentifier: String(lang))
                if(lang == Language.French) {
                    dateFormatter.dateFormat = "d MMMM"
                } else {
                    dateFormatter.dateFormat = "MMMM d"
                }
                
                return weatherInfo.when + " " + dateFormatter.stringFromDate(theDate)
            }
        }
    }
    
    static func addDaystoGivenDate(baseDate:NSDate,NumberOfDaysToAdd:Int)->NSDate
    {
        let dateComponents = NSDateComponents()
        let CurrentCalendar = NSCalendar.currentCalendar()
        let CalendarOption = NSCalendarOptions()
        
        dateComponents.day = NumberOfDaysToAdd
        
        let newDate = CurrentCalendar.dateByAddingComponents(dateComponents, toDate: baseDate, options: CalendarOption)
        return newDate!
    }
    
    static func textToImageMinMax(weather: WeatherInformation)->UIImage{
        let baseImage = getMinMaxImage(weather, header: false)
        let text = String(weather.temperature)
        
        var offsetLeft = 14
        var offsetTop = 6
        var textFont = UIFont.systemFontOfSize(55)
        if text.characters.count == 1 {
            offsetLeft = 28
        } else if text.characters.count == 3 {
            offsetLeft = 8
            offsetTop = 14
            textFont = UIFont.systemFontOfSize(45)
        }
        
        let textColor = UIColor.whiteColor()
        
        //Setup the image context using the passed image.
        UIGraphicsBeginImageContext(baseImage.size)
        
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ]
        
        //Put the image into a rectangle as large as the original image.
        baseImage.drawInRect(CGRectMake(0, 0, baseImage.size.width, baseImage.size.height))
        
        // Creating a point within the space that is as bit as the image.
        let rect: CGRect = CGRectMake(CGFloat(offsetLeft), CGFloat(offsetTop), baseImage.size.width, baseImage.size.height)
        
        text.drawInRect(rect, withAttributes: textFontAttributes)
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the context now that we have the image we need
        UIGraphicsEndImageContext()
        
        return newImage
        
    }
}