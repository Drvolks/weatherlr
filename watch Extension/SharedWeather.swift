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
    
    func getWeather(_ city: City, delegate: WeatherUpdateDelegate) {
        let cachedWeather = ExpiringCache.instance.object(forKey: city.id) as? WeatherInformationWrapper
        
        if let newWrapper = cachedWeather {
            if cacheValid(newWrapper) {
                self.wrapper = newWrapper
                delegate.weatherDidUpdate()
                return
            }
        }
        
        delegate.beforeUpdate()
        
        let url = UrlHelper.getUrl(city)
        
        if let url = URL(string: url) {
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                DispatchQueue.main.async(execute: {
                    if (data != nil && error == nil) {
                        let rssParser = RssParser(xmlData: data!, language: PreferenceHelper.getLanguage())
                        self.wrapper = WeatherHelper.generateWeatherInformation(rssParser, city: city)
                        
                        ExpiringCache.instance.setObject(self.wrapper, forKey: city.id)
                        
                        DispatchQueue.main.async {
                            delegate.weatherDidUpdate()
                        }
                    }
                })
            }
            task.resume()
        }
    }
    
    func cacheValid(_ cache: WeatherInformationWrapper) -> Bool {
        let elapsedTime = Calendar.current.components(.minute, from: cache.lastRefresh as Date, to: Date(), options: []).minute
        if elapsedTime < Constants.WeatherCacheInMinutes {
            return true
        } else {
            return false
        }
    }
    
    func refreshNeeded() -> Bool {
        if let oldCity = wrapper.city {
            if let currentCity = PreferenceHelper.getSelectedCity() {
                if let cachedWeather = ExpiringCache.instance.object(forKey: currentCity.id) as? WeatherInformationWrapper {
                    if !cacheValid(cachedWeather) {
                        return true
                    }
                    else if oldCity.id != currentCity.id {
                        return true
                    }
                    
                    return false
                }
            }
        }
        
        return true
    }
    
    func broadcastUpdate(_ delegate: WeatherUpdateDelegate) {
        wrapper = WeatherInformationWrapper()
        
        delegates.forEach({
            if $0 !== delegate {
                $0.weatherDidUpdate()
            }
        })
    }
    
    func register(_ delegate: WeatherUpdateDelegate) {
        delegates.append(delegate)
    }
    
    func unregister(_ delegate: WeatherUpdateDelegate) {
        for (index, currentDelegate) in delegates.enumerated() {
            if currentDelegate === delegate {
                delegates.remove(at: index)
                break
            }
        }
    }
}
