//
//  InterfaceController.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    @IBOutlet var cityLabel: WKInterfaceLabel!
    @IBOutlet var weatherTable: WKInterfaceTable!
    
    var weatherInformationWrapper = WeatherInformationWrapper()
    var selectedCity:City?

    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        let watchSession = WCSession.defaultSession()
        watchSession.delegate = self
        watchSession.activateSession()
        
        if let city = PreferenceHelper.getSelectedCity() {
            selectedCity = city
            
            let url = UrlHelper.getUrl(city)
            
            if let url = NSURL(string: url) {
                let task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
                    dispatch_async(dispatch_get_main_queue(), {
                        if (data != nil && error == nil) {
                            let rssParser = RssParser(xmlData: data!, language: PreferenceHelper.getLanguage())
                            self.weatherInformationWrapper = WeatherHelper.generateWeatherInformation(rssParser)
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.refresh()
                            }
                        }
                    })
                }
                task.resume()
            }
        }
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        if let nsData = applicationContext[Constants.selectedCityKey] as? NSData {
            let data = NSKeyedUnarchiver.unarchiveObjectWithData(nsData)
            if let city = data as? City {
                PreferenceHelper.saveSelectedCity(city)
                selectedCity = city
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.refresh()
                })
            }
        }
    }
    
    func refresh() {
        if let city = selectedCity {
            var name = city.englishName
            if PreferenceHelper.isFrench() {
                name = city.frenchName
            }
            self.cityLabel.setText(name)
        }
        
        var rowTypes = [String]()
        for index in 0..<weatherInformationWrapper.weatherInformations.count {
            let weather = weatherInformationWrapper.weatherInformations[index]
            if weather.weatherDay == WeatherDay.Now {
                rowTypes.append("currentWeatherRow")
            }
            else if weather.weatherDay == WeatherDay.Today {
                rowTypes.append("nextWeatherRow")
            } else {
                rowTypes.append("weatherRow")
            }
        }
        weatherTable.setRowTypes(rowTypes)

        
        for index in 0..<rowTypes.count {
            let weather = weatherInformationWrapper.weatherInformations[index]
            
            switch(rowTypes[index]) {
            case "currentWeatherRow":
                if let controller = weatherTable.rowControllerAtIndex(index) as? CurrentWeatherRowController {
                    if weatherInformationWrapper.weatherInformations.count > index+1 {
                        let nextWeather = weatherInformationWrapper.weatherInformations[index+1]
                        controller.nextWeather = nextWeather
                    }
                    
                    controller.weather = weather
                }
                break
            case "nextWeatherRow":
                if let controller = weatherTable.rowControllerAtIndex(index) as? NextWeatherRowController {
                    controller.rowIndex = index
                    controller.weather = weather
                }
                break
            case "weatherRow":
                if let controller = weatherTable.rowControllerAtIndex(index) as? WeatherRowController {
                    controller.rowIndex = index
                    controller.weather = weather
                }
                break
            default:
                break
            }
        }
    }
}
