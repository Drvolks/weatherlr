//
//  CityHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-23.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class WeatherHelper {
    static func getWeatherInformations(city:City) -> WeatherInformationWrapper {
        let cache = ExpiringCache.instance
        let cachedWeather = cache.objectForKey(city.id) as? WeatherInformationWrapper
        
        if cachedWeather != nil {
            return cachedWeather!
        }
        
        let url = UrlHelper.getUrl(city)
        
        if let url = NSURL(string: url) {
            if let rssParser = RssParser(url: url, language: PreferenceHelper.getLanguage()) {
                let rssEntries = rssParser.parse()
                let weatherInformationProcess = RssEntryToWeatherInformation(rssEntries: rssEntries)
                let weatherInformations = weatherInformationProcess.perform()
                
                let weatherInformationWrapper = WeatherInformationWrapper(weatherInformations: weatherInformations)
                cache.setObject(weatherInformationWrapper, forKey: city.id)
                return weatherInformationWrapper
            }
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
             .Showers:
            return WeatherStatus.LightRain
        case .AMixOfSunAndCloud,
             .CloudyPeriods,
             .PartlyCloudy:
            return WeatherStatus.AFewClouds
        case .ChanceOfFlurries,
             .ChanceOfLightSnow,
             .CloudyWithXPercentChanceOfFlurries:
            return WeatherStatus.ChanceOfSnow
        case .ChanceOfRainShowersOrFlurries:
            return WeatherStatus.AFewRainShowersOrFlurries
        case .ChanceOfRainShowersOrWetFlurries,
             .RainOrFreezingRain:
            return WeatherStatus.PeriodsOfRainOrFreezingRain
        case .ChanceOfShowersOrDrizzle,
             .ShowersOrDrizzle,
             .RainOrDrizzle,
             .PeriodsOfDrizzleOrRain,
             .PeriodsOfDrizzleMixedWithRain,
             .ChanceOfDrizzleOrRain:
            return WeatherStatus.PeriodsOfRainOrDrizzle
        case .DrizzleMixedWithFreezingDrizzle,
             .FreezingDrizzleOrDrizzle,
             .PeriodsOfDrizzleMixedWithFreezingDrizzle,
             .PeriodsOfFreezingDrizzleOrDrizzle:
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
             .RainMixedWithSnow:
            return WeatherStatus.PeriodsOfRainOrSnow
        case .FreezingRainOrSnow,
             .PeriodsOfSnowMixedWithFreezingRain:
            return WeatherStatus.PeriodsOfLightSnowOrFreezingRain
        case .PeriodsOfLightSnowMixedWithFreezingDrizzle:
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
             .FogPatches:
            return WeatherStatus.Mist
        default:
            return nil
        }
    }
}