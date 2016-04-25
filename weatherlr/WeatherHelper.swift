//
//  CityHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-23.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class WeatherHelper {
    static func getWeatherInformations(city:City) -> [WeatherInformation] {
        let cachedWeather = ExpiringCache.instance.objectForKey(city.id) as? [WeatherInformation]
        
        if cachedWeather != nil {
            return cachedWeather!
        }
        
        let url = UrlHelper.getUrl(city)
        
        if let url = NSURL(string: url) {
            if let rssParser = RssParser(url: url, language: PreferenceHelper.getLanguage()) {
                let rssEntries = rssParser.parse()
                let weatherInformationProcess = RssEntryToWeatherInformation(rssEntries: rssEntries)
                let weatherInformations = weatherInformationProcess.perform()
                
                ExpiringCache.instance.setObject(weatherInformations, forKey: city.id)
                return weatherInformations
            }
        }
        
        return [WeatherInformation]()
    }
}