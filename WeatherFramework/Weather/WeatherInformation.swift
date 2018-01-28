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
    var dateObservation:String
    
    init() {
        temperature = 0
        weatherStatus = .na
        weatherDay = .now
        summary = ""
        detail = ""
        tendancy = Tendency.na
        when = ""
        night = false
        dateObservation = ""
    }
    
    init(temperature: Int, weatherStatus: WeatherStatus, weatherDay: WeatherDay, summary: String, detail: String, tendancy:Tendency, when: String, night: Bool, dateObservation: String) {
        self.temperature = temperature
        self.weatherStatus = weatherStatus
        self.weatherDay = weatherDay
        self.summary = summary
        self.detail = detail
        self.tendancy = tendancy
        self.when = when
        self.night = night
        self.dateObservation = dateObservation
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
}
