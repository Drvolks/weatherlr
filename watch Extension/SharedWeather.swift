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
    
    func getWeather(city: City, callback: () -> Void) {
        let cachedWeather = ExpiringCache.instance.objectForKey(city.id) as? WeatherInformationWrapper
        
        if cachedWeather != nil {
            callback()
            return
        }
        
        let url = UrlHelper.getUrl(city)
        
        if let url = NSURL(string: url) {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
                dispatch_async(dispatch_get_main_queue(), {
                    if (data != nil && error == nil) {
                        let rssParser = RssParser(xmlData: data!, language: PreferenceHelper.getLanguage())
                        self.wrapper = WeatherHelper.generateWeatherInformation(rssParser)
                        
                        ExpiringCache.instance.setObject(self.wrapper, forKey: city.id)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            callback()
                        }
                    }
                })
            }
            task.resume()
        }
    }
    
    func flushWrapper() {
        wrapper = WeatherInformationWrapper()
    }
    
    func broadcastUpdate(delegate: WeatherUpdateDelegate) {
        delegates.forEach({
            if $0 !== delegate {
                $0.weatherDidUpdate()
            }
        })
        
        //let complicationServer = CLKComplicationServer.sharedInstance()
        //for complication in complicationServer.activeComplications! {
        //    complicationServer.reloadTimelineForComplication(complication)
        //}
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