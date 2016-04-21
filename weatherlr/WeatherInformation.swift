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
        if night {
            let nameNight = String(self.weatherStatus) + "Night"
            if let image = UIImage(named: nameNight) {
                return image
            } else {
                if let image = UIImage(named: String(self.weatherStatus)) {
                    return image
                }
            }
        } else {
            if let image = UIImage(named: String(self.weatherStatus)) {
                return image
            }
        }
        
        return UIImage(named: "NA")!
    }
    
    func color() -> UIColor {
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
             .PeriodsOfRainMixedWithSnow,
             .PeriodsOfRain,
             .PeriodsOfLightSnowOrFreezingRain,
             .PeriodsOfFreezingRain,
             .PeriodsOfDrizzleMixedWithFreezingDrizzle,
             .PeriodsOfDrizzle,
             .Overcast,
             .MostlyCloudy,
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
             .AFewRainShowersOrFlurries:
            if night {
                return UIColor(weatherColor: WeatherColor.CloudyNight)
            } else {
                return UIColor(weatherColor: WeatherColor.CloudyDay)
            }
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
             .Blizzard:
            if night {
                return UIColor(weatherColor: WeatherColor.SnowNight)
            } else {
                return UIColor(weatherColor: WeatherColor.SnowDay)
            }
        case .Sunny,
             .PartlyCloudy,
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
             .Blank,
             .NA:
            if night {
                return UIColor(weatherColor: WeatherColor.ClearNight)
            } else {
                return UIColor(weatherColor: WeatherColor.ClearDay)
            }
        default:
            return UIColor(weatherColor: WeatherColor.DefaultColor)
        }
    }
}
