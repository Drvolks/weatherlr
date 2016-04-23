//
//  CityHelper.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-23.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

class CityHelper {
    static func getWeatherInformations(city:City) -> [WeatherInformation] {
        let url = UrlHelper.getUrl(city)
        
        if let url = NSURL(string: url) {
            if let rssParser = RssParser(url: url, language: PreferenceHelper.getLanguage()) {
                let rssEntries = rssParser.parse()
                let weatherInformationProcess = RssEntryToWeatherInformation(rssEntries: rssEntries)
                return weatherInformationProcess.perform()
            }
        }
        
        return [WeatherInformation]()
    }
}