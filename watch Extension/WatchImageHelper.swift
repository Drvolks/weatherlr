//
//  WatchImageHelper.swift
//  weatherlr
//
//  Created by Jean-François Dufour on 17-02-28.
//  Copyright © 2017 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit
import ClockKit

class WatchImageHelper {
    static func getImage(weatherInformation: WeatherInformation) -> CLKImageProvider {
        var image = weatherInformation.image()
        var tint = UIColor.lightGray
        
        switch(weatherInformation.weatherStatus) {
        case .aFewClouds,
             .cloudy,
             .cloudyPeriods,
             .increasingCloudiness,
             .mostlyCloudy,
             .overcast,
             .partlyCloudy:
            image = UIImage(named: "WatchCloudy")!
            tint = UIColor.lightGray
            break
        case .aFewFlurries,
             .blowingSnow,
             .blizzard,
             .chanceOfFlurries,
             .chanceOfLightSnow,
             .chanceOfSnow,
             .chanceOfWetFlurries,
             .driftingSnow,
             .flurries,
             .flurriesAtTimesHeavy,
             .heavySnow,
             .lightSnow,
             .lightSnowAndBlowingSnow,
             .lightSnowshower,
             .lightWetSnow,
             .periodsOfLightSnow,
             .periodsOfSnow,
             .periodsOfSnowAndBlowingSnow,
             .periodsOfWetSnow,
             .snow,
             .snowAndBlowingSnow,
             .snowAtTimesHeavy,
             .snowAtTimesHeavyMixedWithIcePellets,
             .snowGrains,
             .wetFlurries,
             .wetSnow:
            image = UIImage(named: "WatchSnow")!
            tint = UIColor.white
            break
        case .aFewShowersOrThunderstorms,
             .aFewShowersOrDrizzle,
             .aFewShowers,
             .chanceOfDrizzleOrRain,
             .chanceOfFreezingRain,
             .chanceOfRainShowersOrWetFlurries,
             .chanceOfRain,
             .chanceOfRainOrDrizzle,
             .chanceOfShowers,
             .chanceOfShowersAtTimesHeavy,
             .chanceOfShowersOrDrizzle,
             .chanceOfShowersOrThunderstorms,
             .chanceOfThunderstorms,
             .drizzleOrRain,
             .freezingDrizzleOrRain,
             .freezingRain,
             .freezingRainOrRain,
             .heavyRainshower,
             .lightFreezingRain,
             .lightRain,
             .lightRainAndFog,
             .lightRainshower,
             .periodsOfFreezingRain,
             .periodsOfRain,
             .periodsOfRainOrFreezingRain,
             .precipitation,
             .rain,
             .rainAtTimesHeavy,
             .rainAtTimesHeavyOrDrizzle,
             .rainAtTimesHeavyOrFreezingRain,
             .rainOrFreezingRain,
             .showers,
             .showersAtTimesHeavy,
             .showersAtTimesHeavyOrThundershowers,
             .showersOrThunderstorms,
             .thunderstorm,
             .thunderstormWithLightRain,
             .thunderstormWithLightRainshowers:
            image = UIImage(named: "WatchRain")!
            tint = UIColor(weatherColor: WeatherColor.rain)
            break
        case .aMixOfSunAndCloud,
             .clearing,
             .mainlyClear,
             .mainlySunny,
             .sunny:
            image = UIImage(named: "WatchSunny")!
            tint = UIColor.yellow
            break
        case .chanceOfDrizzle,
             .chanceOfDrizzleMixedWithFreezingDrizzle,
             .chanceOfFreezingDrizzle,
             .drizzle,
             .drizzleMixedWithFreezingDrizzle,
             .freezingDrizzle,
             .freezingDrizzleOrDrizzle,
             .lightDrizzleAndFog,
             .lightFreezingDrizzle,
             .periodsOfDrizzle,
             .periodsOfDrizzleMixedWithFreezingDrizzle,
             .periodsOfDrizzleMixedWithRain,
             .periodsOfDrizzleOrFreezingDrizzle,
             .periodsOfDrizzleOrRain,
             .periodsOfFreezingDrizzle,
             .periodsOfFreezingDrizzleOrDrizzle,
             .periodsOfFreezingDrizzleOrRain,
             .periodsOfRainOrDrizzle,
             .rainOrDrizzle,
             .showersOrDrizzle:
            image = UIImage(named: "WatchDrizzle")!
            tint = UIColor(weatherColor: WeatherColor.rain)
            break
        case .freezingRainMixedWithIcePellets,
             .freezingRainOrIcePellets,
             .icePellets,
             .icePelletsOrSnow,
             .icePelletsMixedWithSnow,
             .icePelletsMixedWithFreezingRain,
             .periodsOfFreezingRainMixedWithIcePellets,
             .periodsOfSnowMixedWithIcePellets:
            image = UIImage(named: "WatchIcePellets")!
            tint = UIColor.white
            break
        default:
            break
        }
        
        let imageProvider = CLKImageProvider(onePieceImage: image)
        imageProvider.tintColor = tint
        
        return imageProvider
    }
    
    // TODO  patch temp - merge le code des 2 méthode
    static func getImageProviderFull(weatherInformation: WeatherInformation) -> CLKFullColorImageProvider {
        var image = weatherInformation.image()
        
        switch(weatherInformation.weatherStatus) {
        case .aFewClouds,
             .cloudy,
             .cloudyPeriods,
             .increasingCloudiness,
             .mostlyCloudy,
             .overcast,
             .partlyCloudy:
            image = UIImage(named: "ComplicationCloudy")!
            break
        case .aFewFlurries,
             .blowingSnow,
             .blizzard,
             .chanceOfFlurries,
             .chanceOfLightSnow,
             .chanceOfSnow,
             .chanceOfWetFlurries,
             .driftingSnow,
             .flurries,
             .flurriesAtTimesHeavy,
             .heavySnow,
             .lightSnow,
             .lightSnowAndBlowingSnow,
             .lightSnowshower,
             .lightWetSnow,
             .periodsOfLightSnow,
             .periodsOfSnow,
             .periodsOfSnowAndBlowingSnow,
             .periodsOfWetSnow,
             .snow,
             .snowAndBlowingSnow,
             .snowAtTimesHeavy,
             .snowAtTimesHeavyMixedWithIcePellets,
             .snowGrains,
             .wetFlurries,
             .wetSnow:
            image = UIImage(named: "ComplicationSnow")!
            break
        case .aFewShowersOrThunderstorms,
             .aFewShowersOrDrizzle,
             .aFewShowers,
             .chanceOfDrizzleOrRain,
             .chanceOfFreezingRain,
             .chanceOfRainShowersOrWetFlurries,
             .chanceOfRain,
             .chanceOfRainOrDrizzle,
             .chanceOfShowers,
             .chanceOfShowersAtTimesHeavy,
             .chanceOfShowersOrDrizzle,
             .chanceOfShowersOrThunderstorms,
             .chanceOfThunderstorms,
             .drizzleOrRain,
             .freezingDrizzleOrRain,
             .freezingRain,
             .freezingRainOrRain,
             .heavyRainshower,
             .lightFreezingRain,
             .lightRain,
             .lightRainAndFog,
             .lightRainshower,
             .periodsOfFreezingRain,
             .periodsOfRain,
             .periodsOfRainOrFreezingRain,
             .precipitation,
             .rain,
             .rainAtTimesHeavy,
             .rainAtTimesHeavyOrDrizzle,
             .rainAtTimesHeavyOrFreezingRain,
             .rainOrFreezingRain,
             .showers,
             .showersAtTimesHeavy,
             .showersAtTimesHeavyOrThundershowers,
             .showersOrThunderstorms,
             .thunderstorm,
             .thunderstormWithLightRain,
             .thunderstormWithLightRainshowers:
            image = UIImage(named: "ComplicationRain")!
            break
        case .aMixOfSunAndCloud,
             .clearing,
             .mainlyClear,
             .mainlySunny,
             .sunny:
            image = UIImage(named: "ComplicationSunny")!
            break
        case .chanceOfDrizzle,
             .chanceOfDrizzleMixedWithFreezingDrizzle,
             .chanceOfFreezingDrizzle,
             .drizzle,
             .drizzleMixedWithFreezingDrizzle,
             .freezingDrizzle,
             .freezingDrizzleOrDrizzle,
             .lightDrizzleAndFog,
             .lightFreezingDrizzle,
             .periodsOfDrizzle,
             .periodsOfDrizzleMixedWithFreezingDrizzle,
             .periodsOfDrizzleMixedWithRain,
             .periodsOfDrizzleOrFreezingDrizzle,
             .periodsOfDrizzleOrRain,
             .periodsOfFreezingDrizzle,
             .periodsOfFreezingDrizzleOrDrizzle,
             .periodsOfFreezingDrizzleOrRain,
             .periodsOfRainOrDrizzle,
             .rainOrDrizzle,
             .showersOrDrizzle:
            image = UIImage(named: "ComplicationDrizzle")!
            break
        case .freezingRainMixedWithIcePellets,
             .freezingRainOrIcePellets,
             .icePellets,
             .icePelletsOrSnow,
             .icePelletsMixedWithSnow,
             .icePelletsMixedWithFreezingRain,
             .periodsOfFreezingRainMixedWithIcePellets,
             .periodsOfSnowMixedWithIcePellets:
            image = UIImage(named: "ComplicationIcePellets")!
            break
        default:
            break
        }
        
        let imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        
        return imageProvider
    }
}
