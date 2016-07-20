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
    
    private var delegates = [WeatherUpdateDelegate]()
    
    func getWeather(_ city: City, delegate: WeatherUpdateDelegate) {
        delegate.beforeUpdate()
        
        let url = UrlHelper.getUrl(city)
        
        if let url = URL(string: url) {
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                DispatchQueue.main.async(execute: {
                    if (data != nil && error == nil) {
                        let rssParser = RssParser(xmlData: data!, language: PreferenceHelper.getLanguage())
                        let wrapper = WeatherHelper.generateWeatherInformation(rssParser, city: city)
                        
                        DispatchQueue.main.async {
                            delegate.weatherDidUpdate(wrapper: wrapper)
                        }
                    }
                })
            }
            task.resume()
        }
    }
    
    func broadcastUpdate(_ delegate: WeatherUpdateDelegate) {
        delegates.forEach({
            if $0 !== delegate {
                $0.weatherShouldUpdate()
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
