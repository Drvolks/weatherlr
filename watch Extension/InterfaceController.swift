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


class InterfaceController: WKInterfaceController{
    @IBOutlet var cityLabel: WKInterfaceLabel!
    @IBOutlet var weatherTable: WKInterfaceTable!
    @IBOutlet var selectCityButton: WKInterfaceButton!
    
    var weatherInformationWrapper = WeatherInformationWrapper()
    var selectedCity:City?

    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }

    override func willActivate() {
        super.willActivate()
        
        loadData()
    }
    
    func loadData() {
        initDisplay()
        
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
    
    func initDisplay() {
        if PreferenceHelper.getSelectedCity() != nil {
            cityLabel.setHidden(false)
            cityLabel.setText("Loading".localized())
            selectCityButton.setHidden(true)
        } else {
            cityLabel.setHidden(true)
            selectCityButton.setHidden(false)
        }
        
        weatherTable.setNumberOfRows(0, withRowType: "currentWeatherRow")
        weatherTable.setNumberOfRows(0, withRowType: "nextWeatherRow")
        weatherTable.setNumberOfRows(0, withRowType: "weatherRow")
    }
    
    func refresh() {
        if let city = selectedCity {
            self.cityLabel.setText(CityHelper.cityName(city))
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
                    if index == 0 {
                        controller.previousWeatherPresent = false
                    }
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
    
    @IBAction func selectCity() {
        var citieNames = [String]()
        PreferenceHelper.getFavoriteCities().forEach({
            citieNames.append(CityHelper.cityName($0))
        })
        
        citieNames.appendContentsOf("abcdefghijklmnopqrstuvwxyz".uppercaseString.characters.map { String($0) })
        
        presentTextInputControllerWithSuggestions(citieNames, allowedInputMode: .Plain, completion: { (result) -> Void in
            self.didSayCityName(result)
        })
    }
    
    @IBAction func francaisSelected() {
        PreferenceHelper.saveLanguage(Language.French)
        refresh()
    }
    
    @IBAction func englishSelected() {
        PreferenceHelper.saveLanguage(Language.English)
        refresh()
    }
    
    
    @IBAction func addCitySelected() {
        selectCity()
    }
    
    @IBAction func clearCitySelected() {
        PreferenceHelper.removeFavorites()
    }
    
    func didSayCityName(result: AnyObject?) {
        if let result = result, let choice = result[0] as? String {
            print(choice)
            
            var match = false;
            PreferenceHelper.getFavoriteCities().forEach({
                let name = CityHelper.cityName($0)
                if name == choice {
                    var refresh = true
                    if let selectedCity = PreferenceHelper.getSelectedCity() {
                        if selectedCity.id == $0.id {
                            refresh = false
                        }
                    }
                    if refresh {
                        PreferenceHelper.saveSelectedCity($0)
                        loadData()
                    }
                    match = true
                    return
                }
            })
            
            if match {
                return
            }
     
            let path = NSBundle.mainBundle().pathForResource("Cities", ofType: "plist")
            let allCityList = (NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as? [City])!
            let cities:[City]
            
            if choice.characters.count == 1 {
                cities = CityHelper.searchCityStartingWith(choice, allCityList: allCityList)
            } else {
                cities = CityHelper.searchCity(choice, allCityList: allCityList)
            }
            
            if cities.count == 1 {
                PreferenceHelper.addFavorite(cities[0])
                
                loadData()
            } else {
                pushControllerWithName("SelectCity", context: [Constants.cityListKey : cities, Constants.searchTextKey: choice])
            }
        }
    }
}
