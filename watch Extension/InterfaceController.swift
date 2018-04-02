//
//  InterfaceController.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController, URLSessionDelegate, URLSessionDownloadDelegate, LocationServicesDelegate {
    
    
    @IBOutlet var cityLabel: WKInterfaceLabel!
    @IBOutlet var weatherTable: WKInterfaceTable!
    @IBOutlet var selectCityButton: WKInterfaceButton!
    @IBOutlet var lastRefreshLabel: WKInterfaceLabel!
    @IBOutlet var locatingImage: WKInterfaceImage!
    @IBOutlet var locationErrorLabel: WKInterfaceLabel!
    
    var updatedDate = Date(timeIntervalSince1970: 0)
    var rowTypes = [String]()
    var locationServices:LocationServices?
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        locationServices = LocationServices()
        locationServices?.delegate = self
        locationServices?.start()
        
        selectCityButton.setTitle("Select city".localized())
        
        clearAllMenuItems()
        addMenuItem(with: WKMenuItemIcon.info, title: "Français", action: #selector(InterfaceController.francaisSelected))
        addMenuItem(with: WKMenuItemIcon.info, title: "English", action: #selector(InterfaceController.englishSelected))
        addMenuItem(with: WKMenuItemIcon.more, title: "City".localized(), action: #selector(InterfaceController.addCitySelected))
        addMenuItem(with: WKMenuItemIcon.repeat, title: "Refresh".localized(), action: #selector(InterfaceController.refresh))
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
        if ExtensionDelegateHelper.getSelectedCity() != nil {
            selectCityButton.setHidden(true)
            locatingImage.setHidden(true)
            locationErrorLabel.setHidden(true)
            
            if ExtensionDelegateHelper.refreshNeeded() {
                lastRefreshLabel.setHidden(true)
                
                cityLabel.setHidden(false)
                cityLabel.setText("Loading".localized())
                
                ExtensionDelegateHelper.launchURLSessionNow(self)
            } else if updatedDate.compare(ExtensionDelegateHelper.getWrapper().lastRefresh) != ComparisonResult.orderedSame {
                refreshDisplay()
            }
        } else {
            cityLabel.setHidden(true)
            locationErrorLabel.setHidden(true)
            
            if let city = locationServices?.getCurrentCity() {
                if LocationServices.isUseCurrentLocation(city) {
                    selectCityButton.setHidden(true)
                    locatingImage.setHidden(false)
                    return
                }
            }
            
            if let city = PreferenceHelper.getSelectedCity() {
                if LocationServices.isUseCurrentLocation(city) {
                    locationErrorLabel.setHidden(false)
                }
            }
            
            locatingImage.setHidden(true)
            selectCityButton.setHidden(false)
        }
    }
    
    func refreshDisplay() {
        #if DEBUG
            print("refreshDisplay")
        #endif
        
        let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate
        
        cityLabel.setHidden(false)
        cityLabel.setText("Loading".localized())
        
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
        
        cityLabel.setText("Loading2".localized())
        
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
        
        if let city = ExtensionDelegateHelper.getSelectedCity() {
            self.cityLabel.setText(CityHelper.cityName(city))
        }
        
        lastRefreshLabel.setHidden(false)
        lastRefreshLabel.setText(WeatherHelper.getRefreshTime(watchDelegate.wrapper))
        
        updatedDate = watchDelegate.wrapper.lastRefresh
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
    
    @IBAction func selectCity() {
        var citieNames = [String]()
        let isFrench = PreferenceHelper.isFrench()
        PreferenceHelper.getFavoriteCities().forEach({
            if $0.id == Global.currentLocationCityId {
                if isFrench {
                    citieNames.append($0.frenchName)
                } else {
                    citieNames.append($0.englishName)
                }
            } else {
                if isFrench {
                    citieNames.append($0.frenchName + ", " + $0.province.uppercased())
                } else {
                    citieNames.append($0.englishName + ", " + $0.province.uppercased())
                }
            }
        })
        
        citieNames.append(contentsOf: "abcdefghijklmnopqrstuvwxyz".uppercased().map { String($0) })
        
        presentTextInputController(withSuggestions: citieNames, allowedInputMode: .plain, completion: { (result) -> Void in
            self.didSayCityName(result as AnyObject?)
        })
    }
    
    @objc func francaisSelected() {
        PreferenceHelper.saveLanguage(Language.French)
        ExtensionDelegateHelper.resetWeather()
        loadData()
    }
    
    @objc func englishSelected() {
        PreferenceHelper.saveLanguage(Language.English)
        ExtensionDelegateHelper.resetWeather()
        loadData()
    }
    
    
    @objc func addCitySelected() {
        selectCity()
    }
    
    @objc func refresh() {
        rowTypes = [String]()
        ExtensionDelegateHelper.resetWeather()
        loadData()
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
     
            let cities:[City]
            let useCurrentCity = CityHelper.getCurrentLocationCity()
            
            if choice == useCurrentCity.englishName || choice == useCurrentCity.frenchName {
                cityDidChange(useCurrentCity)
                return
            }
            
            if choice.count == 1 {
                cities = CityHelper.searchCityStartingWith(choice, allCityList: (locationServices?.getAllCityList())!)
            } else {
                cities = CityHelper.searchCity(choice, allCityList: (locationServices?.getAllCityList())!)
            }
            
            if cities.count == 1 {
                cityDidChange(cities[0])
            } else {
                pushController(withName: "SelectCity", context: [Constants.cityListKey : cities, Constants.searchTextKey: choice])
            }
        }
    }
    
    func cityDidChange(_ city: City) {
        PreferenceHelper.addFavorite(city)
        locationServices?.updateCity(city)
        refresh()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        #if DEBUG
            print("Watch urlSession didFinishDownloadingTo")
        #endif
        
        if let city = ExtensionDelegateHelper.getSelectedCity() {
            do {
                let xmlData = try Data(contentsOf: location)
                ExtensionDelegateHelper.setWrapper(WeatherHelper.getWeatherInformationsNoCache(xmlData, city: city))
                
                #if DEBUG
                    print("Watch wrapper updated")
                #endif
                
                ExtensionDelegateHelper.updateComplication()
                
                refreshDisplay()
            } catch {
                print("Error info: \(error)")
            }
        } else {
            print("Watch urlSession didFinishDownloadingTo - no selected city")
        }
    }
    
    func cityHasBeenUpdated(_ city: City) {
        ExtensionDelegateHelper.setSelectedCity(city)
        ExtensionDelegateHelper.launchURLSessionNow(self)
    }
    
    func getAllCityList() -> [City] {
        let path = Bundle.main.path(forResource: "Cities", ofType: "plist")
        return (NSKeyedUnarchiver.unarchiveObject(withFile: path!) as? [City])!
    }
    
    func unknownCity(_ cityName:String) {
        locationErrorLabel.setText("The iPhone detected that you are located in".localized() + " " + cityName + ", " + "but this city is not in the Environment Canada list. Do you want to select a city yourself?")
        refresh()
    }
    
    func notInCanada() {
        locationErrorLabel.setText("The iPhone detected that you are not located in Canada".localized())
        refresh()
    }
    
    func errorLocating(_ errorCode:Int) {
        // TODO retier code erreur
        locationErrorLabel.setText("Unable to detect your current location".localized() + " (code " + String(errorCode) + ")")
        refresh()
    }
}
