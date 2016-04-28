//
//  WeatherInformation.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class WeatherInformation {
    var temperature:Int
    var weatherStatus:WeatherStatus
    var weatherDay:WeatherDay
    var detail:String
    var summary:String
    var tendancy:Tendency
    var when: String
    var night:Bool
    
    init() {
        temperature = 0
        weatherStatus = .NA
        weatherDay = .Now
        summary = ""
        detail = ""
        tendancy = Tendency.NA
        when = ""
        night = false
    }
    
    init(temperature: Int, weatherStatus: WeatherStatus, weatherDay: WeatherDay, summary: String, detail: String, tendancy:Tendency, when: String, night: Bool) {
        self.temperature = temperature
        self.weatherStatus = weatherStatus
        self.weatherDay = weatherDay
        self.summary = summary
        self.detail = detail
        self.tendancy = tendancy
        self.when = when
        self.night = night
    }
    
    func image() -> UIImage {
        var status = self.weatherStatus
        if let substitute = WeatherHelper.getImageSubstitute(self.weatherStatus) {
            status = substitute
        }
        
        if night {
            let nameNight = String(status) + "Night"
            if let image = UIImage(named: nameNight) {
                return image
            } else {
                if let image = UIImage(named: String(status)) {
                    return image
                }
            }
        } else {
            if let image = UIImage(named: String(status)) {
                return image
            }
        }
        
        return UIImage(named: "NA")!
    }
    
    func color() -> WeatherColor {
        
        switch weatherStatus {
        case .SnowOrRain,
             .ShowersOrDrizzle,
             .Showers,
             .RainShowersOrFlurries,
             .RainOrFreezingRain,
             .RainAtTimesHeavy,
             .Rain,
             .PeriodsOfSnowOrRain,
             .PeriodsOfRainOrSnow,
             .PeriodsOfRainOrFreezingRain,
             .PeriodsOfRainOrDrizzle,
             .PeriodsOfRainMixedWithSnow,
             .PeriodsOfRain,
             .PeriodsOfLightSnowOrFreezingRain,
             .PeriodsOfFreezingRain,
             .PeriodsOfDrizzleMixedWithFreezingDrizzle,
             .PeriodsOfDrizzle,
             .Overcast,
             .Mist,
             .LightRainshower,
             .LightRain,
             .LightFreezingDrizzle,
             .IncreasingCloudiness,
             .FreezingDrizzleOrDrizzle,
             .FlurriesOrRainShowers,
             .DrizzleMixedWithFreezingDrizzle,
             .Drizzle,
             .Cloudy,
             .ChanceOfShowersOrDrizzle,
             .ChanceOfShowers,
             .ChanceOfRainShowersOrFlurries,
             .ChanceOfDrizzleMixedWithFreezingDrizzle,
             .AFewShowers,
             .AFewRainShowersOrFlurries,
             .ChanceOfRainShowersOrWetFlurries,
             .SnowMixedWithRain,
             .FreezingRainOrSnow,
             .LightFreezingRain,
             .WetSnow,
             .WetFlurries,
             .FreezingFog,
             .Fog:
            return WeatherColor.CloudyDay
        case .Snow,
             .PeriodsOfSnowAndBlowingSnow,
             .PeriodsOfSnow,
             .PeriodsOfLightSnow,
             .LightSnowshower,
             .LightSnowAndBlowingSnow,
             .LightSnow,
             .Flurries,
             .DriftingSnow,
             .CloudyWithXPercentChanceOfFlurries,
             .BlowingSnow,
             .Blizzard,
             .SnowAndBlowingSnow,
             .HeavySnow,
             .FlurriesAtTimesHeavy,
             .ChanceOfSnow,
             .ChanceOfLightSnow,
             .SnowAtTimesHeavy,
             .SnowGrains:
            return WeatherColor.SnowDay
        case .Sunny,
             .PartlyCloudy,
             .MostlyCloudy,
             .MainlySunny,
             .MainlyClear,
             .CloudyPeriods,
             .Clearing,
             .Clear,
             .ChanceOfFlurries,
             .ChanceOfDrizzle,
             .AMixOfSunAndCloud,
             .AFewFlurries,
             .AFewClouds,
             .IceCrystals,
             .Blank,
             .NA:
            return WeatherColor.ClearDay
        default:
            return WeatherColor.DefaultColor
        }
    }
}
