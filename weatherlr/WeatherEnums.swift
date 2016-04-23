//
//  WeatherStatus.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

enum WeatherStatus {
    case AFewClouds
    case AFewFlurries
    case AFewRainShowersOrFlurries
    case AFewShowers
    case AMixOfSunAndCloud
    case Blizzard
    case BlowingSnow
    case ChanceOfDrizzle
    case ChanceOfDrizzleMixedWithFreezingDrizzle
    case ChanceOfFlurries
    case ChanceOfRainShowersOrFlurries
    case ChanceOfShowers
    case ChanceOfShowersOrDrizzle
    case Clear
    case Clearing
    case Cloudy
    case CloudyPeriods
    case CloudyWithXPercentChanceOfFlurries
    case DriftingSnow
    case Drizzle
    case DrizzleMixedWithFreezingDrizzle
    case Flurries
    case FlurriesOrRainShowers
    case FreezingDrizzleOrDrizzle
    case IncreasingCloudiness
    case LightFreezingDrizzle
    case LightRain
    case LightRainshower
    case LightSnow
    case LightSnowAndBlowingSnow
    case LightSnowshower
    case MainlyClear
    case MainlySunny
    case Mist
    case MostlyCloudy
    case Overcast
    case PartlyCloudy
    case PeriodsOfDrizzle
    case PeriodsOfDrizzleMixedWithFreezingDrizzle
    case PeriodsOfFreezingRain
    case PeriodsOfLightSnow
    case PeriodsOfLightSnowOrFreezingRain
    case PeriodsOfRain
    case PeriodsOfRainMixedWithSnow
    case PeriodsOfRainOrDrizzle
    case PeriodsOfRainOrFreezingRain
    case PeriodsOfRainOrSnow
    case PeriodsOfSnow
    case PeriodsOfSnowAndBlowingSnow
    case PeriodsOfSnowOrRain
    case Rain
    case RainAtTimesHeavy
    case RainOrFreezingRain
    case RainShowersOrFlurries
    case Showers
    case ShowersOrDrizzle
    case Snow
    case SnowOrRain
    case Sunny
    case Blank
    case NA
    case UnitTest
}

enum WeatherColor : Int {
    case ClearDay = 0x009ec2
    case ClearNight = 0x00465c
    case CloudyDay = 0x9eacb4
    case CloudyNight = 0x555d62
    case SnowDay = 0xb4b7b7
    case SnowNight = 0x7d7f7f
    case DefaultColor = 0x009ec1
}

enum WeatherDay : Int {
    case Now = 0
    case Today = 1
    case Tomorow = 2
    case NA = -99
}

enum Tendency {
    case Minimum
    case Maximum
    case Steady
    case NA
}

enum Language: String {
    case French = "fr"
    case English = "en"
    
    static let all = [French, English]
}