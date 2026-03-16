//
//  CityHelper.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-23.
//  Copyright © 2016 drvolks. All rights reserved.
//

import UIKit
import CoreText

public class WeatherHelper {
    static let offline = false
    static let cache = ExpiringCache<WeatherInformationWrapper>()

    public static func getWeatherInformations(_ city:City) -> WeatherInformationWrapper {
        if offline {
            return getOfflineWeather()
        } else {
            if let cachedWeather = cache.object(forKey: city.id) {
                return cachedWeather
            }

            let weatherInformationWrapper = getWeatherInformationsNoCache(city)
            cache.setObject(weatherInformationWrapper, forKey: city.id)

            return weatherInformationWrapper
        }
    }
    
    public static func getWeatherInformationsNoCache(_ city:City) -> WeatherInformationWrapper {
        let url = UrlHelper.getUrl(city)

        if let url = URL(string: url) {
            if let data = try? Data(contentsOf: url) {
                return getWeatherInformationsNoCache(data, city: city)
            }
        }

        return WeatherInformationWrapper()
    }

    public static func getWeatherInformationsNoCache(_ data:Data, city:City) -> WeatherInformationWrapper {
        let parser = JsonWeatherParser(data: data, language: PreferenceHelper.getLanguage())
        let (weatherInformations, alerts, hourlyForecasts) = parser.parse()

        let weatherInformationWrapper = WeatherInformationWrapper(weatherInformations: weatherInformations, alerts: alerts, hourlyForecasts: hourlyForecasts, city: city)
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

            var city = City()
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
    
    public static func getImageSubstitute(_ weatherStatus: WeatherStatus) -> WeatherStatus? {
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

    public static func getNightImageName(_ status: WeatherStatus) -> String? {
        switch status {
        case .sunny, .mainlySunny, .clear:
            return "clear"
        case .aFewClouds, .aMixOfSunAndCloud, .cloudyPeriods, .partlyCloudy:
            return "aFewCloudsNight"
        case .clearing:
            return "clearingNight"
        case .mostlyCloudy:
            return "clearingNight"
        default:
            return nil
        }
    }

    // Environment Canada icon code → image asset name
    // Reference: https://collaboration.cmc.ec.gc.ca/cmc/cmos/public_doc/msc-data/citypage-weather/
    public static func imageNameForIconCode(_ code: Int) -> String? {
        switch code {
        // Day-only conditions (0-9)
        case 0:  return "sunny"                              // Sunny
        case 1:  return "mainlySunny"                        // A few clouds
        case 2:  return "aFewClouds"                         // A mix of sun and cloud / Partly cloudy
        case 3:  return "mostlyCloudy"                       // Mostly cloudy
        case 4:  return "clearing"                           // Increasing cloudiness
        case 5:  return "clearing"                           // Clearing
        case 6:  return "chanceOfShowers"                    // Chance of showers
        case 7:  return "aFewRainShowersOrFlurries"          // A few flurries or rain showers
        case 8:  return "chanceOfSnow"                       // A few flurries / Chance of flurries
        case 9:  return "chanceOfShowersOrThunderstorms"     // Chance of thunderstorms

        // Day and night conditions (10-28)
        case 10: return "cloudy"                             // Cloudy / Overcast
        case 11: return "lightRain"                          // Light rain showers
        case 12: return "rain"                               // Rain showers
        case 13: return "rain"                               // Rain
        case 14: return "freezingRain"                       // Freezing rain
        case 15: return "periodsOfRainOrSnow"                // Rain or snow mixed
        case 16: return "lightSnow"                          // Light snow
        case 17: return "snow"                               // Snow
        case 18: return "blizzard"                           // Blizzard
        case 19: return "chanceOfShowersOrThunderstorms"     // Thunderstorms
        case 22: return "aFewClouds"                         // A mix of sun and cloud (alt)
        case 23: return "mist"                               // Haze
        case 24: return "mist"                               // Fog
        case 25: return "driftingSnow"                       // Drifting snow
        case 26: return "iceCrystals"                        // Ice crystals
        case 27: return "icePellets"                         // Ice pellets / Hail
        case 28: return "drizzle"                            // Drizzle

        // Night-only conditions (30-39, mirror day codes 0-9)
        case 30: return "clear"                              // Clear
        case 31: return "aFewCloudsNight"                    // A few clouds
        case 32: return "aFewCloudsNight"                    // Partly cloudy
        case 33: return "aFewCloudsNight"                    // Mostly cloudy
        case 34: return "clearingNight"                      // Increasing cloudiness
        case 35: return "clearingNight"                      // Clearing
        case 36: return "chanceOfShowers"                    // Chance of showers
        case 37: return "aFewRainShowersOrFlurries"          // A few flurries or rain showers
        case 38: return "chanceOfSnow"                       // A few flurries / Chance of flurries
        case 39: return "chanceOfShowersOrThunderstorms"     // Chance of thunderstorms

        // Extended conditions (40+)
        case 40: return "periodsOfSnowAndBlowingSnow"        // Blowing snow
        case 44: return "smoke"                              // Smoke

        default: return nil
        }
    }

    public static func getMinMaxImage(_ weatherInfo: WeatherInformation, header: Bool) -> UIImage {
        let name = getMinMaxImageName(weatherInfo)
        
        if header {
            return UIImage(named: name + "Header")!
        } else {
            return UIImage(named: name)!
        }
    }
    
    public static func getMinMaxImageName(_ weatherInfo: WeatherInformation) -> String {
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
    
    public static func getIndexAjust(_ weatherInformations:[WeatherInformation]) -> Int {
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
    
    public static func getWeatherTextWithMinMax(_ weatherInfo: WeatherInformation) -> String {
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
    
    public static func getWeatherDayWhenText(_ weatherInfo: WeatherInformation) -> String {
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
    
    public static func addDaystoGivenDate(_ baseDate:Date,NumberOfDaysToAdd:Int)->Date {
        var dateComponents = DateComponents()
        let CurrentCalendar = Calendar.current
        
        dateComponents.day = NumberOfDaysToAdd
        
        let newDate = CurrentCalendar.date(byAdding: dateComponents, to: baseDate)
        return newDate!
    }
    
    public static func textToImageMinMax(_ weather: WeatherInformation)->UIImage{
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

        #if os(watchOS)
        let size = baseImage.size
        guard let cgImage = baseImage.cgImage else { return baseImage }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return baseImage }

        // Flip the entire context so UIKit-style drawing works (origin top-left)
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // Draw the base image (needs explicit flip since context is now flipped)
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        // Push CGContext as current UIKit context so String.draw works
        UIGraphicsPushContext(context)
        let textFontAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: textColor
        ]
        let rect = CGRect(x: CGFloat(offsetLeft), y: CGFloat(offsetTop), width: size.width, height: size.height)
        text.draw(in: rect, withAttributes: textFontAttributes)
        UIGraphicsPopContext()

        guard let resultCGImage = context.makeImage() else { return baseImage }
        return UIImage(cgImage: resultCGImage)
        #else
        let renderer = UIGraphicsImageRenderer(size: baseImage.size)
        let newImage = renderer.image { context in
            let textFontAttributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: textColor,
                ] as [NSAttributedString.Key : Any]

            baseImage.draw(in: CGRect(x: 0, y: 0, width: baseImage.size.width, height: baseImage.size.height))

            let rect: CGRect = CGRect(x: CGFloat(offsetLeft), y: CGFloat(offsetTop), width: baseImage.size.width, height: baseImage.size.height)

            text.draw(in: rect, withAttributes: textFontAttributes)
        }

        return newImage
        #endif
    }
    
    public static func getRefreshTime(_ wrapper: WeatherInformationWrapper) -> String {
        let lang = PreferenceHelper.getLanguage()

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: String(describing: lang))
        dateFormatter.timeStyle = .short
        return "Last refresh".localized() + " " + dateFormatter.string(from: wrapper.lastRefresh as Date)
    }

}
