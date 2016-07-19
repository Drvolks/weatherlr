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


class InterfaceController: WKInterfaceController, WeatherUpdateDelegate {
    @IBOutlet var cityLabel: WKInterfaceLabel!
    @IBOutlet var weatherTable: WKInterfaceTable!
    @IBOutlet var selectCityButton: WKInterfaceButton!
    @IBOutlet var lastRefreshLabel: WKInterfaceLabel!
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    deinit {
        SharedWeather.instance.unregister(self)
    }
    
    override func awake(withContext context: AnyObject?) {
        super.awake(withContext: context)
        
        SharedWeather.instance.register(self)
        
        selectCityButton.setTitle("Select city".localized())
        
        clearAllMenuItems()
        addMenuItem(with: WKMenuItemIcon.info, title: "Français", action: #selector(InterfaceController.francaisSelected))
        addMenuItem(with: WKMenuItemIcon.info, title: "English", action: #selector(InterfaceController.englishSelected))
        addMenuItem(with: WKMenuItemIcon.more, title: "City".localized(), action: #selector(InterfaceController.addCitySelected))
    }

    override func willActivate() {
        super.willActivate()
        
        if SharedWeather.instance.refreshNeeded() {
            loadData()
        }
    }
    
    func loadData() {
        if let city = PreferenceHelper.getSelectedCity() {
            SharedWeather.instance.getWeather(city, delegate: self)
        } else {
            cityLabel.setHidden(true)
            selectCityButton.setHidden(false)
        }
    }
    
    func beforeUpdate() {
        lastRefreshLabel.setHidden(true)
        
        cityLabel.setHidden(false)
        cityLabel.setText("Loading".localized())
        selectCityButton.setHidden(true)
    }
    
    func weatherDidUpdate() {
        if let city = PreferenceHelper.getSelectedCity() {
            self.cityLabel.setText(CityHelper.cityName(city))
        }
        
        lastRefreshLabel.setHidden(false)
        lastRefreshLabel.setText(WeatherHelper.getRefreshTime(SharedWeather.instance.wrapper))
        
        var rowTypes = [String]()
        for index in 0..<SharedWeather.instance.wrapper.weatherInformations.count {
            let weather = SharedWeather.instance.wrapper.weatherInformations[index]
            if weather.weatherDay == WeatherDay.now {
                rowTypes.append("currentWeatherRow")
            }
            else if weather.weatherDay == WeatherDay.today {
                rowTypes.append("nextWeatherRow")
            } else {
                rowTypes.append("weatherRow")
            }
        }
        weatherTable.setRowTypes(rowTypes)

        
        for index in 0..<rowTypes.count {
            let weather = SharedWeather.instance.wrapper.weatherInformations[index]
            
            switch(rowTypes[index]) {
            case "currentWeatherRow":
                if let controller = weatherTable.rowController(at: index) as? CurrentWeatherRowController {
                    if SharedWeather.instance.wrapper.weatherInformations.count > index+1 {
                        let nextWeather = SharedWeather.instance.wrapper.weatherInformations[index+1]
                        controller.nextWeather = nextWeather
                    }
                    
                    controller.weather = weather
                }
                break
            case "nextWeatherRow":
                if let controller = weatherTable.rowController(at: index) as? NextWeatherRowController {
                    if index == 0 {
                        controller.previousWeatherPresent = false
                    }
                    controller.weather = weather
                }
                break
            case "weatherRow":
                if let controller = weatherTable.rowController(at: index) as? WeatherRowController {
                    controller.rowIndex = index
                    controller.weather = weather
                }
                break
            default:
                break
            }
        }
    }
    
    func selectCity() {
        var citieNames = [String]()
        PreferenceHelper.getFavoriteCities().forEach({
            citieNames.append(CityHelper.cityName($0) + ", " + $0.province.uppercased())
        })
        
        citieNames.append(contentsOf: "abcdefghijklmnopqrstuvwxyz".uppercased().characters.map { String($0) })
        
        presentTextInputController(withSuggestions: citieNames, allowedInputMode: .plain, completion: { (result) -> Void in
            self.didSayCityName(result)
        })
    }
    
    func francaisSelected() {
        PreferenceHelper.saveLanguage(Language.French)
        loadData()
    }
    
    func englishSelected() {
        PreferenceHelper.saveLanguage(Language.English)
        loadData()
    }
    
    
    func addCitySelected() {
        selectCity()
    }
    
    func didSayCityName(_ result: AnyObject?) {
        if let result = result, let choice = result[0] as? String {
            var match = false;
            PreferenceHelper.getFavoriteCities().forEach({
                let name = CityHelper.cityName($0) + ", " + $0.province.uppercased()
                if name == choice {
                    var refresh = true
                    if let selectedCity = PreferenceHelper.getSelectedCity() {
                        if selectedCity.id == $0.id {
                            refresh = false
                        }
                    }
                    if refresh {
                        cityDidChange($0)
                    }
                    match = true
                    return
                }
            })
            
            if match {
                return
            }
     
            let path = Bundle.main.pathForResource("Cities", ofType: "plist")
            let allCityList = (NSKeyedUnarchiver.unarchiveObject(withFile: path!) as? [City])!
            let cities:[City]
            
            if choice.characters.count == 1 {
                cities = CityHelper.searchCityStartingWith(choice, allCityList: allCityList)
            } else {
                cities = CityHelper.searchCity(choice, allCityList: allCityList)
            }
            
            if cities.count == 1 {
                cityDidChange(cities[0])
            } else {
                pushController(withName: "SelectCity", context: [Constants.cityListKey : cities, Constants.searchTextKey: choice, "delegate": self])
            }
        }
    }
    
    func cityDidChange(_ city: City) {
        PreferenceHelper.addFavorite(city)
        SharedWeather.instance.broadcastUpdate(self)
        loadData()
    }
}
