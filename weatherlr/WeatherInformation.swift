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
    var weatherStatusImage:UIImage
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
        weatherStatusImage = UIImage(named: "NA")!
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
        
        if let image = UIImage(named: String(self.weatherStatus)) {
            self.weatherStatusImage = image
        } else {
            weatherStatusImage = UIImage(named: "NA")!
        }
    }
}
