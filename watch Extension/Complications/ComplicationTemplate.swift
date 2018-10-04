//
//  WatchTemplate.swift
//  watch Extension
//
//  Created by drvolks on 2018-10-04.
//  Copyright © 2018 drvolks. All rights reserved.
//

import Foundation
import WatchKit

protocol ComplicationTemplateProtocol {
    func generate(_ weather: WeatherInformation?, nextWeather: WeatherInformation?, city:City) -> CLKComplicationTemplate
    func initialState() -> CLKComplicationTemplate
    func demoState() -> CLKComplicationTemplate
}

open class ComplicationTemplate {
    func temp(weather: WeatherInformation) -> String {
        return String(weather.temperature) + "°"
    }
}
