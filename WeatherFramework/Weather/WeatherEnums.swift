//
//  WeatherStatus.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

enum WeatherStatus {
    case aFewClouds
    case aFewFlurries
    case aFewRainShowersOrFlurries
    case aFewShowers
    case aFewShowersOrDrizzle
    case aFewShowersOrThunderstorms
    case aFewRainShowersOrWetFlurries
    case aMixOfSunAndCloud
    case blizzard
    case blowingSnow
    case chanceOfDrizzle
    case chanceOfDrizzleMixedWithFreezingDrizzle
    case chanceOfDrizzleOrRain
    case chanceOfFlurries
    case chanceOfFreezingDrizzle
    case chanceOfFreezingRain
    case chanceOfLightSnow
    case chanceOfRainShowersOrFlurries
    case chanceOfRainShowersOrWetFlurries
    case chanceOfRain
    case chanceOfRainOrDrizzle
    case chanceOfShowers
    case chanceOfShowersAtTimesHeavy
    case chanceOfShowersOrDrizzle
    case chanceOfShowersOrThunderstorms
    case chanceOfSnow
    case chanceOfSnowOrRain
    case chanceOfSnowMixedWithRain
    case chanceOfSnowAtTimesHeavy
    case chanceOfThunderstorms
    case chanceOfWetFlurries
    case chanceOfWetFlurriesOrRainShowers
    case clear
    case clearing
    case cloudy
    case cloudyPeriods
    case cloudyWithXPercentChanceOfFlurries
    case driftingSnow
    case drizzle
    case drizzleMixedWithFreezingDrizzle
    case drizzleOrRain
    case flurries
    case flurriesAtTimesHeavy
    case flurriesOrRainShowers
    case fog
    case fogDissipating
    case fogPatches
    case freezingDrizzle
    case freezingDrizzleOrDrizzle
    case freezingDrizzleOrRain
    case freezingFog
    case freezingRain
    case freezingRainMixedWithIcePellets
    case freezingRainMixedWithSnow
    case freezingRainOrSnow
    case freezingRainOrRain
    case freezingRainOrIcePellets
    case haze
    case heavyRainshower
    case heavySnow
    case iceCrystals
    case icePellets
    case icePelletsOrSnow
    case icePelletsMixedWithSnow
    case icePelletsMixedWithFreezingRain
    case increasingCloudiness
    case lightDrizzleAndFog
    case lightFreezingDrizzle
    case lightFreezingRain
    case lightRain
    case lightRainAndDrizzle
    case lightRainAndFog
    case lightRainshower
    case lightSnow
    case lightSnowAndBlowingSnow
    case lightSnowShowerAndBlowingSnow
    case lightSnowMixedWithRain
    case lightSnowOrFreezingRain
    case lightSnowOrRain
    case lightSnowshower
    case lightWetSnow
    case mainlyClear
    case mainlySunny
    case mist
    case mostlyCloudy
    case overcast
    case partlyCloudy
    case periodsOfDrizzle
    case periodsOfDrizzleMixedWithFreezingDrizzle
    case periodsOfDrizzleMixedWithRain
    case periodsOfDrizzleOrFreezingDrizzle
    case periodsOfDrizzleOrRain
    case periodsOfFreezingDrizzle
    case periodsOfFreezingDrizzleOrDrizzle
    case periodsOfFreezingDrizzleOrRain
    case periodsOfFreezingRain
    case periodsOfFreezingRainMixedWithIcePellets
    case periodsOfFreezingRainOrSnow
    case periodsOfLightSnow
    case periodsOfLightSnowOrFreezingRain
    case periodsOfLightSnowMixedWithFreezingDrizzle
    case periodsOfLightSnowMixedWithRain
    case periodsOfRain
    case periodsOfRainMixedWithSnow
    case periodsOfRainOrDrizzle
    case periodsOfRainOrFreezingRain
    case periodsOfRainOrSnow
    case periodsOfSnow
    case periodsOfSnowAndBlowingSnow
    case periodsOfSnowMixedWithFreezingRain
    case periodsOfSnowMixedWithRain
    case periodsOfSnowMixedWithFreezingDrizzle
    case periodsOfSnowMixedWithIcePellets
    case periodsOfSnowOrFreezingDrizzle
    case periodsOfSnowOrRain
    case periodsOfWetSnow
    case periodsOfWetSnowOrRain
    case precipitation
    case rain
    case rainAtTimesHeavy
    case rainAtTimesHeavyOrDrizzle
    case rainAtTimesHeavyOrSnow
    case rainAtTimesHeavyOrFreezingRain
    case rainMixedWithFreezingRain
    case rainMixedWithSnow
    case rainOrDrizzle
    case rainOrFreezingRain
    case rainShower
    case rainShowersOrFlurries
    case rainShowersOrWetFlurries
    case showers
    case showersAtTimesHeavy
    case showersAtTimesHeavyOrThundershowers
    case showersOrDrizzle
    case showersOrThunderstorms
    case smoke
    case snow
    case snowAndBlowingSnow
    case snowAtTimesHeavy
    case snowAtTimesHeavyOrRain
    case snowAtTimesHeavyMixedWithRain
    case snowAtTimesHeavyMixedWithIcePellets
    case snowGrains
    case snowMixedWithFreezingDrizzle
    case snowMixedWithIcePellets
    case snowMixedWithRain
    case snowOrFreezingRain
    case snowOrIcePellets
    case snowOrRain
    case sunny
    case thunderstorm
    case thunderstormWithLightRain
    case thunderstormWithLightRainshowers
    case wetFlurries
    case wetFlurriesOrRainShowers
    case wetSnow
    case blank
    case na
    case unitTest
}

enum WeatherColor : Int {
    case rain = 0x1fbfff
    case defaultColor = 0x1f4f74
}

enum WeatherDay : Int {
    case now = -1
    case today = 0
    case tomorow = 1
    case day2 = 2
    case day3 = 3
    case day4 = 4
    case day5 = 5
    case day6 = 6
    case day7 = 7
    case day8 = 8
    case day9 = 9
    case day10 = 10
    case day11 = 11
    case day12 = 12
    case day13 = 13
    case day14 = 14
    case day15 = 15
    case day16 = 16
    case day17 = 17
    case day18 = 18
    case day19 = 19
    case day20 = 20
    case na = -99
}

enum Tendency {
    case minimum
    case maximum
    case steady
    case na
}

enum Language: String {
    case French = "fr"
    case English = "en"
    
    static let all = [French, English]
}

enum AlertType {
    case warning
    case ended
    case none
}
