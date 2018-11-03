//
//  CityHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-23.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherHelper {
    static let offline = false
    
    static func getWeatherInformations(_ city:City) -> WeatherInformationWrapper {
        if offline {
            return getOfflineWeather()
        } else {
            let cache = ExpiringCache.instance
            let cachedWeather = cache.object(forKey: city.id as NSString) as? WeatherInformationWrapper
            
            if cachedWeather != nil {
                return cachedWeather!
            }
            
            let weatherInformationWrapper = getWeatherInformationsNoCache(city)
            cache.setObject(weatherInformationWrapper, forKey: city.id as NSString)
            
            return weatherInformationWrapper
        }
    }
    
    static func getWeatherInformationsNoCache(_ city:City) -> WeatherInformationWrapper {
        
        let url = UrlHelper.getUrl(city)
        
        if let url = URL(string: url) {
            if let rssParser = RssParser(url: url, language: PreferenceHelper.getLanguage()) {
                return generateWeatherInformation(rssParser, city: city)
            }
        }
        
        return WeatherInformationWrapper()
    }
    
    static func getWeatherInformationsNoCache(_ data:Data, city:City) -> WeatherInformationWrapper {
        let rssParser = RssParser(xmlData: data, language: PreferenceHelper.getLanguage())
        return generateWeatherInformation(rssParser, city: city)
    }
    
    static func generateWeatherInformation(_ rssParser: RssParser, city: City) -> WeatherInformationWrapper {
        let rssEntries = rssParser.parse()
        let weatherInformationProcess = RssEntryToWeatherInformation(rssEntries: rssEntries)
        let weatherInformations = weatherInformationProcess.perform()
        let alerts = weatherInformationProcess.getAlerts()
        
        let weatherInformationWrapper = WeatherInformationWrapper(weatherInformations: weatherInformations, alerts: alerts, city: city)
        return weatherInformationWrapper
    }
    
    static func getOfflineWeather() -> WeatherInformationWrapper {
        let path = Bundle.main.path(forResource: "nu-29_English", ofType: "xml")
        let url = URL(fileURLWithPath: path!)
        
        if let rssParser = RssParser(url: url, language: PreferenceHelper.getLanguage()) {
            let rssEntries = rssParser.parse()
            let weatherInformationProcess = RssEntryToWeatherInformation(rssEntries: rssEntries)
            let weatherInformations = weatherInformationProcess.perform()
            let alerts = weatherInformationProcess.getAlerts()

            let city = City()
            city.englishName = "Offline city en"
            city.frenchName = "Offline city fr"
            city.id = "0"
            city.radarId = "0"
            city.province = "qc"
            
            let weatherInformationWrapper = WeatherInformationWrapper(weatherInformations: weatherInformations, alerts: alerts, city: city)
            return weatherInformationWrapper
        }
        
        return WeatherInformationWrapper()
    }
    
    static func getImageSubstitute(_ weatherStatus: WeatherStatus) -> WeatherStatus? {
        switch(weatherStatus) {
        case .mainlyClear:
            return WeatherStatus.mainlySunny
        case .aFewFlurries,
             .lightSnowshower,
             .periodsOfLightSnow,
             .periodsOfSnow:
            return WeatherStatus.lightSnow
        case .aFewShowers,
             .lightRainshower,
             .periodsOfRain,
             .showers,
             .chanceOfRain,
             .precipitation,
             .rainShower:
            return WeatherStatus.lightRain
        case .aMixOfSunAndCloud,
             .cloudyPeriods,
             .partlyCloudy:
            return WeatherStatus.aFewClouds
        case .chanceOfFlurries,
             .chanceOfLightSnow,
             .cloudyWithXPercentChanceOfFlurries:
            return WeatherStatus.chanceOfSnow
        case .chanceOfRainShowersOrFlurries,
             .periodsOfLightSnowMixedWithRain,
             .chanceOfSnowMixedWithRain,
             .chanceOfSnowOrRain:
            return WeatherStatus.aFewRainShowersOrFlurries
        case .rainOrFreezingRain,
             .freezingRainOrRain,
             .rainAtTimesHeavyOrFreezingRain,
             .rainMixedWithFreezingRain:
            return WeatherStatus.periodsOfRainOrFreezingRain
        case .chanceOfShowersOrDrizzle,
             .showersOrDrizzle,
             .rainOrDrizzle,
             .periodsOfDrizzleOrRain,
             .periodsOfDrizzleMixedWithRain,
             .chanceOfDrizzleOrRain,
             .drizzleOrRain,
             .rainAtTimesHeavyOrDrizzle,
             .aFewShowersOrDrizzle,
             .chanceOfRainOrDrizzle,
             .lightRainAndDrizzle:
            return WeatherStatus.periodsOfRainOrDrizzle
        case .freezingDrizzleOrRain:
            return WeatherStatus.periodsOfFreezingDrizzleOrRain
        case .drizzleMixedWithFreezingDrizzle,
             .freezingDrizzleOrDrizzle,
             .periodsOfDrizzleMixedWithFreezingDrizzle,
             .periodsOfFreezingDrizzleOrDrizzle,
             .periodsOfDrizzleOrFreezingDrizzle:
            return WeatherStatus.chanceOfDrizzleMixedWithFreezingDrizzle
        case .flurries:
            return WeatherStatus.snow
        case .flurriesAtTimesHeavy,
             .chanceOfSnowAtTimesHeavy:
            return WeatherStatus.snowAtTimesHeavy
        case .flurriesOrRainShowers,
             .periodsOfRainMixedWithSnow,
             .periodsOfSnowOrRain,
             .rainShowersOrFlurries,
             .snowMixedWithRain,
             .snowOrRain,
             .snowAtTimesHeavyMixedWithRain,
             .periodsOfSnowMixedWithRain,
             .rainMixedWithSnow,
             .lightSnowMixedWithRain,
             .lightSnowOrRain,
             .rainAtTimesHeavyOrSnow,
             .snowAtTimesHeavyOrRain:
            return WeatherStatus.periodsOfRainOrSnow
        case .freezingRainOrSnow,
             .periodsOfSnowMixedWithFreezingRain,
             .periodsOfFreezingRainOrSnow,
             .freezingRainMixedWithSnow,
             .snowOrFreezingRain,
             .lightSnowOrFreezingRain:
            return WeatherStatus.periodsOfLightSnowOrFreezingRain
        case .periodsOfLightSnowMixedWithFreezingDrizzle,
             .periodsOfSnowOrFreezingDrizzle,
             .periodsOfSnowMixedWithFreezingDrizzle:
            return WeatherStatus.snowMixedWithFreezingDrizzle
        case .increasingCloudiness:
            return WeatherStatus.clearing
        case .overcast:
            return WeatherStatus.cloudy
        case .periodsOfDrizzle:
            return WeatherStatus.chanceOfDrizzle
        case .snowAndBlowingSnow,
             .lightSnowShowerAndBlowingSnow:
            return WeatherStatus.lightSnowAndBlowingSnow
        case .wetFlurries:
            return WeatherStatus.wetSnow
        case .fog,
             .haze,
             .fogPatches,
             .fogDissipating:
            return WeatherStatus.mist
        case .periodsOfFreezingDrizzle,
             .chanceOfFreezingDrizzle:
            return WeatherStatus.lightFreezingDrizzle
        case .periodsOfFreezingRainMixedWithIcePellets,
             .icePelletsMixedWithFreezingRain,
             .freezingRainOrIcePellets:
            return WeatherStatus.freezingRainMixedWithIcePellets
        case .chanceOfWetFlurriesOrRainShowers,
             .periodsOfWetSnowOrRain,
             .wetFlurriesOrRainShowers,
             .rainShowersOrWetFlurries,
             .aFewRainShowersOrWetFlurries:
            return WeatherStatus.chanceOfRainShowersOrWetFlurries
        case .lightWetSnow:
            return WeatherStatus.chanceOfWetFlurries
        case .heavyRainshower,
             .chanceOfShowersAtTimesHeavy,
             .showersAtTimesHeavy:
            return WeatherStatus.rainAtTimesHeavy
        case .aFewShowersOrThunderstorms,
             .thunderstorm,
             .thunderstormWithLightRainshowers,
             .showersOrThunderstorms,
             .thunderstormWithLightRain,
             .chanceOfThunderstorms,
             .showersAtTimesHeavyOrThundershowers:
            return WeatherStatus.chanceOfShowersOrThunderstorms
        case .snowOrIcePellets,
             .icePelletsOrSnow,
             .snowAtTimesHeavyMixedWithIcePellets,
             .icePelletsMixedWithSnow,
             .periodsOfSnowMixedWithIcePellets:
            return WeatherStatus.snowMixedWithIcePellets
        case .chanceOfFreezingRain,
             .lightFreezingRain:
            return WeatherStatus.lightFreezingRain
        default:
            return nil
        }
    }
    
    static func getMinMaxImage(_ weatherInfo: WeatherInformation, header: Bool) -> UIImage {
        let name = getMinMaxImageName(weatherInfo)
        
        if header {
            return UIImage(named: name + "Header")!
        } else {
            return UIImage(named: name)!
        }
    }
    
    static func getMinMaxImageName(_ weatherInfo: WeatherInformation) -> String {
        var name = "up"
        
        if weatherInfo.tendancy == Tendency.minimum {
            name = "down"
        } else if weatherInfo.tendancy == Tendency.steady {
            if weatherInfo.night {
                name = "down"
            }
        }
        
        return name
    }
    
    static func getIndexAjust(_ weatherInformations:[WeatherInformation]) -> Int {
        var indexAjust = 1
        
        if weatherInformations.count == 0 {
            return indexAjust
        }
        
        let weatherInfoBase = weatherInformations[0]
        if weatherInfoBase.weatherDay != WeatherDay.now {
            indexAjust = 0
        }
        
        return indexAjust
    }
    
    static func getWeatherTextWithMinMax(_ weatherInfo: WeatherInformation) -> String {
        var minMax = "Max "
        if weatherInfo.tendancy == Tendency.minimum {
            minMax = "Min "
        } else if weatherInfo.tendancy == Tendency.steady {
            if weatherInfo.night {
                minMax = ""
            }
        }
        
        return minMax + String(weatherInfo.temperature) + "°"
    }
    
    static func getWeatherDayWhenText(_ weatherInfo: WeatherInformation) -> String {
        if weatherInfo.weatherDay == WeatherDay.today {
            if weatherInfo.night {
                return weatherInfo.when
            } else {
                return "Today".localized()
            }
        } else {
            if weatherInfo.night {
                return weatherInfo.when
            } else {
                let today = Date()
                let theDate = addDaystoGivenDate(today, NumberOfDaysToAdd: weatherInfo.weatherDay.rawValue)
                let dateFormatter = DateFormatter()
                let lang = PreferenceHelper.getLanguage()
                dateFormatter.locale = Locale(identifier: String(describing: lang))
                if(lang == Language.French) {
                    dateFormatter.dateFormat = "d MMMM"
                } else {
                    dateFormatter.dateFormat = "MMMM d"
                }
                
                return weatherInfo.when + " " + dateFormatter.string(from: theDate)
            }
        }
    }
    
    static func addDaystoGivenDate(_ baseDate:Date,NumberOfDaysToAdd:Int)->Date
    {
        var dateComponents = DateComponents()
        let CurrentCalendar = Calendar.current
        
        dateComponents.day = NumberOfDaysToAdd
        
        let newDate = CurrentCalendar.date(byAdding: dateComponents, to: baseDate)
        return newDate!
    }
    
    static func textToImageMinMax(_ weather: WeatherInformation)->UIImage{
        let baseImage = getMinMaxImage(weather, header: false)
        let text = String(weather.temperature)
        
        var offsetLeft = 20
        var offsetTop = 10
        var textFont = UIFont.systemFont(ofSize: 55)
        if text.count == 1 {
            offsetLeft = 34
        } else if text.count == 3 {
            offsetLeft = 14
            offsetTop = 14
            textFont = UIFont.systemFont(ofSize: 45)
        }
        
        let textColor = UIColor.white
        
        //Setup the image context using the passed image.
        UIGraphicsBeginImageContext(baseImage.size)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        
        //Put the image into a rectangle as large as the original image.
        baseImage.draw(in: CGRect(x: 0, y: 0, width: baseImage.size.width, height: baseImage.size.height))
        
        // Creating a point within the space that is as bit as the image.
        let rect: CGRect = CGRect(x: CGFloat(offsetLeft), y: CGFloat(offsetTop), width: baseImage.size.width, height: baseImage.size.height)
        
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // End the context now that we have the image we need
        UIGraphicsEndImageContext()
        
        return newImage
        
    }
    
    static func getRefreshTime(_ wrapper: WeatherInformationWrapper) -> String {
        let lang = PreferenceHelper.getLanguage()
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: String(describing: lang))
        dateFormatter.timeStyle = .short
        return "Last refresh".localized() + " " + dateFormatter.string(from: wrapper.lastRefresh as Date)
    }
}
