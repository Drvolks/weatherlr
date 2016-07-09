//
//  SharedWeather.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-09.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class SharedWeather {
    static let instance = SharedWeather()
    
    var wrapper = WeatherInformationWrapper()
    
    func getWeather(city: City, callback: (() -> Void)!) {
        let cachedWeather = ExpiringCache.instance.objectForKey(city.id) as? WeatherInformationWrapper
        
        if cachedWeather != nil {
            return
        }
        
        let url = UrlHelper.getUrl(city)
        
        if let url = NSURL(string: url) {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
                dispatch_async(dispatch_get_main_queue(), {
                    if (data != nil && error == nil) {
                        let rssParser = RssParser(xmlData: data!, language: PreferenceHelper.getLanguage())
                        self.wrapper = WeatherHelper.generateWeatherInformation(rssParser)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            callback()
                        }
                    }
                })
            }
            task.resume()
        }
    }
}