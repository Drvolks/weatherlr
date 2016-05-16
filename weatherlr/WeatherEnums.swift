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
    case AFewShowersOrDrizzle
    case AMixOfSunAndCloud
    case Blizzard
    case BlowingSnow
    case ChanceOfDrizzle
    case ChanceOfDrizzleMixedWithFreezingDrizzle
    case ChanceOfDrizzleOrRain
    case ChanceOfFlurries
    case ChanceOfFreezingDrizzle
    case ChanceOfLightSnow
    case ChanceOfRainShowersOrFlurries
    case ChanceOfRainShowersOrWetFlurries
    case ChanceOfRain
    case ChanceOfShowers
    case ChanceOfShowersOrDrizzle
    case ChanceOfShowersOrThunderstorms
    case ChanceOfSnow
    case ChanceOfWetFlurries
    case ChanceOfWetFlurriesOrRainShowers
    case Clear
    case Clearing
    case Cloudy
    case CloudyPeriods
    case CloudyWithXPercentChanceOfFlurries
    case DriftingSnow
    case Drizzle
    case DrizzleMixedWithFreezingDrizzle
    case DrizzleOrRain
    case Flurries
    case FlurriesAtTimesHeavy
    case FlurriesOrRainShowers
    case Fog
    case FogPatches
    case FreezingDrizzle
    case FreezingDrizzleOrDrizzle
    case FreezingDrizzleOrRain
    case FreezingFog
    case FreezingRain
    case FreezingRainMixedWithIcePellets
    case FreezingRainMixedWithSnow
    case FreezingRainOrSnow
    case Haze
    case HeavySnow
    case IceCrystals
    case IncreasingCloudiness
    case LightDrizzleAndFog
    case LightFreezingDrizzle
    case LightFreezingRain
    case LightRain
    case LightRainAndFog
    case LightRainshower
    case LightSnow
    case LightSnowAndBlowingSnow
    case LightSnowMixedWithRain
    case LightSnowOrRain
    case LightSnowshower
    case LightWetSnow
    case MainlyClear
    case MainlySunny
    case Mist
    case MostlyCloudy
    case Overcast
    case PartlyCloudy
    case PeriodsOfDrizzle
    case PeriodsOfDrizzleMixedWithFreezingDrizzle
    case PeriodsOfDrizzleMixedWithRain
    case PeriodsOfDrizzleOrFreezingDrizzle
    case PeriodsOfDrizzleOrRain
    case PeriodsOfFreezingDrizzle
    case PeriodsOfFreezingDrizzleOrDrizzle
    case PeriodsOfFreezingDrizzleOrRain
    case PeriodsOfFreezingRain
    case PeriodsOfFreezingRainMixedWithIcePellets
    case PeriodsOfFreezingRainOrSnow
    case PeriodsOfLightSnow
    case PeriodsOfLightSnowOrFreezingRain
    case PeriodsOfLightSnowMixedWithFreezingDrizzle
    case PeriodsOfLightSnowMixedWithRain
    case PeriodsOfRain
    case PeriodsOfRainMixedWithSnow
    case PeriodsOfRainOrDrizzle
    case PeriodsOfRainOrFreezingRain
    case PeriodsOfRainOrSnow
    case PeriodsOfSnow
    case PeriodsOfSnowAndBlowingSnow
    case PeriodsOfSnowMixedWithFreezingRain
    case PeriodsOfSnowMixedWithRain
    case PeriodsOfSnowMixedWithFreezingDrizzle
    case PeriodsOfSnowOrFreezingDrizzle
    case PeriodsOfSnowOrRain
    case PeriodsOfWetSnow
    case PeriodsOfWetSnowOrRain
    case Precipitation
    case Rain
    case RainAtTimesHeavy
    case RainAtTimesHeavyOrDrizzle
    case RainMixedWithSnow
    case RainOrDrizzle
    case RainOrFreezingRain
    case RainShowersOrFlurries
    case Showers
    case ShowersOrDrizzle
    case Smoke
    case Snow
    case SnowAndBlowingSnow
    case SnowAtTimesHeavy
    case SnowAtTimesHeavyMixedWithRain
    case SnowGrains
    case SnowMixedWithFreezingDrizzle
    case SnowMixedWithIcePellets
    case SnowMixedWithRain
    case SnowOrFreezingRain
    case SnowOrRain
    case Sunny
    case WetFlurries
    case WetSnow
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
    case Day2 = 3
    case Day3 = 4
    case Day4 = 5
    case Day5 = 6
    case Day6 = 7
    case Day7 = 8
    case Day8 = 9
    case Day9 = 10
    case Day10 = 11
    case Day11 = 12
    case Day12 = 13
    case Day13 = 14
    case Day14 = 15
    case Day15 = 16
    case Day16 = 17
    case Day17 = 18
    case Day18 = 19
    case Day19 = 20
    case Day20 = 21
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

enum AlertType {
    case Warning
    case Ended
    case None
}