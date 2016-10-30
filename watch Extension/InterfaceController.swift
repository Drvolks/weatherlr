//
//  InterfaceController.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    @IBOutlet var cityLabel: WKInterfaceLabel!
    @IBOutlet var weatherTable: WKInterfaceTable!
    @IBOutlet var selectCityButton: WKInterfaceButton!
    @IBOutlet var lastRefreshLabel: WKInterfaceLabel!
    
    var initialState = true
    var rowTypes = [String]()
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        selectCityButton.setTitle("Select city".localized())
        
        clearAllMenuItems()
        addMenuItem(with: WKMenuItemIcon.info, title: "Français", action: #selector(InterfaceController.francaisSelected))
        addMenuItem(with: WKMenuItemIcon.info, title: "English", action: #selector(InterfaceController.englishSelected))
        addMenuItem(with: WKMenuItemIcon.more, title: "City".localized(), action: #selector(InterfaceController.addCitySelected))
    }

    override func willActivate() {
        super.willActivate()

        loadData()
    }
    
    override func willDisappear() {
        if weatherTable.numberOfRows > 0 {
            weatherTable.scrollToRow(at: 0)
        }
    }
    
    func loadData() {
        if PreferenceHelper.getSelectedCity() != nil {
            if ExtensionDelegateHelper.refreshNeeded() {
                lastRefreshLabel.setHidden(true)
                
                cityLabel.setHidden(false)
                cityLabel.setText("Loading".localized())
                selectCityButton.setHidden(true)
                
                ExtensionDelegateHelper.launchURLSession()
            } else if initialState {
                refreshDisplay()
                initialState = false
            }
        } else {
            cityLabel.setHidden(true)
            selectCityButton.setHidden(false)
        }
    }
    
    func refreshDisplay() {
        cityLabel.setText("Loading".localized())
        
        lastRefreshLabel.setHidden(false)
        let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate
        lastRefreshLabel.setText(WeatherHelper.getRefreshTime(watchDelegate.wrapper))
        
        if !rowTypesValid() {
            objc_sync_enter(rowTypes)
            rowTypes = [String]()
            for index in 0..<watchDelegate.wrapper.weatherInformations.count {
                let weather = watchDelegate.wrapper.weatherInformations[index]
                if weather.weatherDay == WeatherDay.now {
                    rowTypes.append("currentWeatherRow")
                }
                else if weather.weatherDay == WeatherDay.today {
                    rowTypes.append("nextWeatherRow")
                } else {
                    rowTypes.append("weatherRow")
                }
            }
            objc_sync_exit(rowTypes)
            weatherTable.setRowTypes(rowTypes)
        }
        
        for index in 0..<rowTypes.count {
            let weather = watchDelegate.wrapper.weatherInformations[index]
            
            switch(rowTypes[index]) {
            case "currentWeatherRow":
                if let controller = weatherTable.rowController(at: index) as? CurrentWeatherRowController {
                    if watchDelegate.wrapper.weatherInformations.count > index+1 {
                        let nextWeather = watchDelegate.wrapper.weatherInformations[index+1]
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
        
        if let city = PreferenceHelper.getSelectedCity() {
            self.cityLabel.setText(CityHelper.cityName(city))
        }
        
        watchDelegate.scheduleSnapshot()
        watchDelegate.updateComplication()
    }
    
    func rowTypesValid() -> Bool {
        let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate
        let wrapper = watchDelegate.wrapper
        
        if rowTypes.count == 0 || wrapper.weatherInformations.count == 0 {
            return false
        }
        
        if rowTypes.count != wrapper.weatherInformations.count {
            return false
        }
        
        let type = rowTypes[0]
        var typeWeatherDay = WeatherDay.now
        if type !=  "currentWeatherRow" {
            typeWeatherDay = WeatherDay.na
        }
        let weatherDay = wrapper.weatherInformations[0].weatherDay
        
        if weatherDay != typeWeatherDay {
            return false
        }
        
        return true
    }
    
    func selectCity() {
        var citieNames = [String]()
        PreferenceHelper.getFavoriteCities().forEach({
            citieNames.append(CityHelper.cityName($0) + ", " + $0.province.uppercased())
        })
        
        citieNames.append(contentsOf: "abcdefghijklmnopqrstuvwxyz".uppercased().characters.map { String($0) })
        
        presentTextInputController(withSuggestions: citieNames, allowedInputMode: .plain, completion: { (result) -> Void in
            self.didSayCityName(result as AnyObject?)
        })
    }
    
    func francaisSelected() {
        PreferenceHelper.saveLanguage(Language.French)
        ExtensionDelegateHelper.resetWeather()
        loadData()
    }
    
    func englishSelected() {
        PreferenceHelper.saveLanguage(Language.English)
        ExtensionDelegateHelper.resetWeather()
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
     
            let path = Bundle.main.path(forResource: "Cities", ofType: "plist")
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
                pushController(withName: "SelectCity", context: [Constants.cityListKey : cities, Constants.searchTextKey: choice])
            }
        }
    }
    
    func cityDidChange(_ city: City) {
        PreferenceHelper.instance.addFavorite(city)
        loadData()
    }
}
