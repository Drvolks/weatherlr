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
    
    func getWeather(city: City, delegate: WeatherUpdateDelegate) {
        let cachedWeather = ExpiringCache.instance.objectForKey(city.id) as? WeatherInformationWrapper
        
        if let newWrapper = cachedWeather {
            let elapsedTime = minutesFrom(newWrapper.lastRefresh)
            if elapsedTime < 30 {
                self.wrapper = newWrapper
                delegate.weatherDidUpdate()
                return
            }
        }
        
        delegate.beforeUpdate()
        
        let url = UrlHelper.getUrl(city)
        
        if let url = NSURL(string: url) {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
                dispatch_async(dispatch_get_main_queue(), {
                    if (data != nil && error == nil) {
                        let rssParser = RssParser(xmlData: data!, language: PreferenceHelper.getLanguage())
                        self.wrapper = WeatherHelper.generateWeatherInformation(rssParser, city: city)
                        
                        ExpiringCache.instance.setObject(self.wrapper, forKey: city.id)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            delegate.weatherDidUpdate()
                        }
                    }
                })
            }
            task.resume()
        }
    }
    
    func minutesFrom(date: NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Minute, fromDate: date, toDate: NSDate(), options: []).minute
    }
    
    func refreshNeeded() -> Bool {
        if let oldCity = wrapper.city {
            if let currentCity = PreferenceHelper.getSelectedCity() {
                let cachedWeather = ExpiringCache.instance.objectForKey(currentCity.id) as? WeatherInformationWrapper
                
                if cachedWeather != nil {
                    if oldCity.id != currentCity.id {
                        return true
                    }
                    
                    return false
                }
            }
        }
        
        return true
    }
    
    func broadcastUpdate(delegate: WeatherUpdateDelegate) {
        wrapper = WeatherInformationWrapper()
        
        delegates.forEach({
            if $0 !== delegate {
                $0.weatherDidUpdate()
            }
        })
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