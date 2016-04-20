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
    case AMixOfSunAndCloud
    case ChanceOfFlurries
    case ChanceOfRainShowersOrFlurries
    case ChanceOfShowers
    case Clear
    case Clearing
    case Cloudy
    case CloudyPeriods
    case CloudyWithXPercentChanceOfFlurries
    case LightRain
    case LightRainshower
    case LightSnow
    case MainlySunny
    case Mist
    case MostlyCloudy
    case PartlyCloudy
    case PeriodsOfRain
    case PeriodsOfRainOrSnow
    case PeriodsOfSnow
    case Rain
    case RainAtTimesHeavy
    case RainShowersOrFlurries
    case Showers
    case Snow
    case SnowOrRain
    case Sunny
    case NA
    case UnitTest
}

enum WeatherColor : Int {
    case ClearDay = 0x009ec2
    case ClearNight = 0x00465c
    case CloudyDay = 0x9eacb4
    case CloudyNight = 0x778289
    case SnowDay = 0xb4b7b7
    case SnowNight = 0xaaadad
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

enum Language {
    case French
    case Enhlish
}