//
//  WeatherInformation.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

public class WeatherInformation {
    public var temperature:Int
    public var weatherStatus:WeatherStatus
    public var weatherDay:WeatherDay
    public var detail:String
    public var summary:String
    public var tendancy:Tendency
    public var when: String
    public var night:Bool
    public var dateObservation:String
    
    public init() {
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
    
    public init(temperature: Int, weatherStatus: WeatherStatus, weatherDay: WeatherDay, summary: String, detail: String, tendancy:Tendency, when: String, night: Bool, dateObservation: String) {
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
    
    public func image() -> UIImage {
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
