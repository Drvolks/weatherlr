//
//  SharedWeather.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-07-09.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import ClockKit

class SharedWeather {
    static let instance = SharedWeather()
    
    var wrapper = WeatherInformationWrapper()
    private var delegates = [WeatherUpdateDelegate]()
    
    func getWeather(city: City) {
        delegates.forEach({
            $0.beforeUpdate()
        })
        
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
                            self.broadcastUpdate()
                        }
                    }
                })
            }
            task.resume()
        }
    }
    
    func broadcastUpdate() {
        delegates.forEach({
            $0.weatherDidUpdate()
        })
        
        let complicationServer = CLKComplicationServer.sharedInstance()
        for complication in complicationServer.activeComplications! {
            complicationServer.reloadTimelineForComplication(complication)
        }
    }
    
    func register(delegate: WeatherUpdateDelegate) {
        delegates.append(delegate)
    }
    
    func unregister(delegate: WeatherUpdateDelegate) {
        for (index, currentDelegate) in delegates.enumerate() {
            if currentDelegate === delegate {
                delegates.removeAtIndex(index)
                break
            }
        }
    }
}