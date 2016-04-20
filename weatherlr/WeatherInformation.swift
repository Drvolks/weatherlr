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
        case .AFewRainShowersOrFlurries,
             .ChanceOfRainShowersOrFlurries,
             .ChanceOfShowers,
             .Cloudy,
             .CloudyWithXPercentChanceOfFlurries,
             .LightRain,
             .LightRainshower,
             .Mist,
             .MostlyCloudy,
             .PeriodsOfRain,
             .PeriodsOfRainOrSnow,
             .Rain,
             .RainAtTimesHeavy,
             .RainShowersOrFlurries,
             .Showers,
             .SnowOrRain:
            if night {
                return UIColor(weatherColor: WeatherColor.CloudyNight)
            } else {
                return UIColor(weatherColor: WeatherColor.CloudyDay)
            }
        case .AFewFlurries,
             .ChanceOfFlurries,
             .LightSnow,
             .PeriodsOfSnow,
             .Snow:
            if night {
                return UIColor(weatherColor: WeatherColor.SnowNight)
            } else {
                return UIColor(weatherColor: WeatherColor.SnowDay)
            }
        default:
            if night {
                return UIColor(weatherColor: WeatherColor.ClearNight)
            } else {
                return UIColor(weatherColor: WeatherColor.ClearDay)
            }
        }
    }
}
