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
        weatherStatus = .na
        weatherDay = .now
        summary = ""
        detail = ""
        tendancy = Tendency.na
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
            let nameNight = String(describing: status) + "Night"
            if let image = UIImage(named: nameNight) {
                return image
            } else {
                if let image = UIImage(named: String(describing: status)) {
                    return image
                }
            }
        } else {
            if let image = UIImage(named: String(describing: status)) {
                return image
            }
        }
        
        return UIImage(named: "na")!
    }
    
    func color() -> WeatherColor {
        
        switch weatherStatus {
        case .snowOrRain,
             .showersOrDrizzle,
             .showers,
             .rainShowersOrFlurries,
             .rainOrFreezingRain,
             .rainAtTimesHeavy,
             .rain,
             .periodsOfSnowOrRain,
             .periodsOfRainOrSnow,
             .periodsOfRainOrFreezingRain,
             .periodsOfRainOrDrizzle,
             .periodsOfRainMixedWithSnow,
             .periodsOfRain,
             .periodsOfLightSnowOrFreezingRain,
             .periodsOfFreezingRain,
             .periodsOfDrizzleMixedWithFreezingDrizzle,
             .periodsOfDrizzle,
             .overcast,
             .mist,
             .lightRainshower,
             .lightRain,
             .lightFreezingDrizzle,
             .increasingCloudiness,
             .freezingDrizzleOrDrizzle,
             .flurriesOrRainShowers,
             .drizzleMixedWithFreezingDrizzle,
             .drizzle,
             .cloudy,
             .chanceOfShowersOrDrizzle,
             .chanceOfShowers,
             .chanceOfRainShowersOrFlurries,
             .chanceOfDrizzleMixedWithFreezingDrizzle,
             .aFewShowers,
             .aFewRainShowersOrFlurries,
             .chanceOfRainShowersOrWetFlurries,
             .snowMixedWithRain,
             .freezingRainOrSnow,
             .lightFreezingRain,
             .wetSnow,
             .wetFlurries,
             .freezingFog,
             .fog,
             .haze,
             .snowAtTimesHeavyMixedWithRain,
             .periodsOfSnowMixedWithRain,
             .periodsOfDrizzleOrRain,
             .rainOrDrizzle,
             .lightDrizzleAndFog,
             .lightRainAndFog,
             .periodsOfDrizzleMixedWithRain,
             .periodsOfSnowMixedWithFreezingRain,
             .fogPatches,
             .rainMixedWithSnow,
             .periodsOfLightSnowMixedWithFreezingDrizzle,
             .smoke,
             .snowMixedWithFreezingDrizzle,
             .periodsOfFreezingDrizzleOrDrizzle,
             .chanceOfDrizzleOrRain,
             .chanceOfWetFlurries,
             .periodsOfFreezingDrizzleOrRain,
             .periodsOfFreezingDrizzle,
             .periodsOfFreezingRainOrSnow,
             .freezingRainMixedWithIcePellets,
             .periodsOfFreezingRainMixedWithIcePellets,
             .chanceOfShowersOrThunderstorms,
             .chanceOfWetFlurriesOrRainShowers,
             .chanceOfRain,
             .lightWetSnow,
             .precipitation,
             .drizzleOrRain,
             .freezingRainMixedWithSnow,
             .freezingDrizzleOrRain,
             .rainAtTimesHeavyOrDrizzle,
             .periodsOfLightSnowMixedWithRain,
             .aFewShowersOrDrizzle,
             .periodsOfWetSnowOrRain,
             .lightSnowMixedWithRain,
             .periodsOfDrizzleOrFreezingDrizzle,
             .periodsOfWetSnow,
             .periodsOfSnowOrFreezingDrizzle,
             .chanceOfFreezingDrizzle,
             .freezingDrizzle,
             .periodsOfSnowMixedWithFreezingDrizzle,
             .lightSnowOrRain,
             .freezingRain,
             .snowOrFreezingRain,
             .heavyRainshower,
             .aFewShowersOrThunderstorms,
             .thunderstorm,
             .thunderstormWithLightRainshowers,
             .wetFlurriesOrRainShowers,
             .lightSnowOrFreezingRain,
             .rainAtTimesHeavyOrSnow,
             .snowAtTimesHeavyOrRain,
             .fogDissipating,
             .showersOrThunderstorms,
             .thunderstormWithLightRain,
             .chanceOfRainOrDrizzle,
             .chanceOfSnowMixedWithRain,
             .chanceOfSnowOrRain,
             .chanceOfShowersAtTimesHeavy,
             .showersAtTimesHeavy,
             .chanceOfThunderstorms,
             .showersAtTimesHeavyOrThundershowers,
             .rainShowersOrWetFlurries,
             .chanceOfFreezingRain,
             .freezingRainOrRain,
             .freezingRainOrIcePellets,
             .icePelletsMixedWithFreezingRain,
             .rainAtTimesHeavyOrFreezingRain,
             .rainMixedWithFreezingRain,
             .lightRainAndDrizzle:
            return WeatherColor.cloudyDay
        case .snow,
             .periodsOfSnowAndBlowingSnow,
             .periodsOfSnow,
             .periodsOfLightSnow,
             .lightSnowshower,
             .lightSnowAndBlowingSnow,
             .lightSnow,
             .flurries,
             .driftingSnow,
             .cloudyWithXPercentChanceOfFlurries,
             .blowingSnow,
             .blizzard,
             .snowAndBlowingSnow,
             .heavySnow,
             .flurriesAtTimesHeavy,
             .chanceOfSnow,
             .chanceOfLightSnow,
             .snowAtTimesHeavy,
             .snowGrains,
             .snowMixedWithIcePellets,
             .icePelletsOrSnow,
             .snowOrIcePellets,
             .icePellets,
             .icePelletsMixedWithSnow,
             .periodsOfSnowMixedWithIcePellets,
             .snowAtTimesHeavyMixedWithIcePellets,
             .lightSnowShowerAndBlowingSnow:
            return WeatherColor.snowDay
        case .sunny,
             .partlyCloudy,
             .mostlyCloudy,
             .mainlySunny,
             .mainlyClear,
             .cloudyPeriods,
             .clearing,
             .clear,
             .chanceOfFlurries,
             .chanceOfDrizzle,
             .aMixOfSunAndCloud,
             .aFewFlurries,
             .aFewClouds,
             .iceCrystals,
             .blank,
             .na:
            return WeatherColor.clearDay
        default:
            return WeatherColor.defaultColor
        }
    }
}
