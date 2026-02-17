//
//  InterfaceController.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation

class InterfaceController: WKInterfaceController, @preconcurrency URLSessionDelegate, @preconcurrency URLSessionDownloadDelegate, @preconcurrency LocationServicesDelegate {
    
    
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
        
        selectCityButton.setTitle("Select city".localized())
        
        clearAllMenuItems()
        addMenuItem(with: WKMenuItemIcon.info, title: "Français", action: #selector(InterfaceController.francaisSelected))
        addMenuItem(with: WKMenuItemIcon.info, title: "English", action: #selector(InterfaceController.englishSelected))
        addMenuItem(with: WKMenuItemIcon.more, title: "City".localized(), action: #selector(InterfaceController.addCitySelected))
        addMenuItem(with: WKMenuItemIcon.repeat, title: "Refresh".localized(), action: #selector(InterfaceController.refresh))
    }

    override func willActivate() {
        super.willActivate()

        loadData(showError:false)
    }
    
    override func willDisappear() {
        if weatherTable.numberOfRows > 0 {
            weatherTable.scrollToRow(at: 0)
        }
    }
    
    func loadData(showError:Bool) {
        let city = PreferenceHelper.getCityToUse()

        if(showError) {
            locationErrorLabel.setHidden(false)
        } else {
            locationErrorLabel.setHidden(true)
        }
        
        selectCityButton.setHidden(false)
        cityLabel.setHidden(false)
        
        if LocationServices.isUseCurrentLocation(city) {
            if(showError) {
                locatingImage.setHidden(true)
            } else {
                locatingImage.setHidden(false)
            }
            cityLabel.setText("Locating".localized())

            locationServices?.start()
            locationServices?.updateCity(city)

            if ExtensionDelegateHelper.refreshNeeded() {
                lastRefreshLabel.setHidden(true)
                cityLabel.setText("Loading".localized())
            } else if updatedDate.compare(ExtensionDelegateHelper.getWrapper().lastRefresh) != ComparisonResult.orderedSame {
                refreshDisplay()
            }
        } else {
            locatingImage.setHidden(true)
            
            if ExtensionDelegateHelper.refreshNeeded() {
                lastRefreshLabel.setHidden(true)
                cityLabel.setText("Loading".localized())
                
                ExtensionDelegateHelper.launchURLSessionNow(self)
            } else if updatedDate.compare(ExtensionDelegateHelper.getWrapper().lastRefresh) != ComparisonResult.orderedSame {
                refreshDisplay()
            }
        }
    }
    
    func refreshDisplay() {
        #if DEBUG
            print("refreshDisplay")
        #endif

        let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate

        cityLabel.setHidden(false)
        cityLabel.setText("Loading".localized())

        rowTypes = [String]()

        if !rowTypesValid() {
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
        }

        weatherTable.setRowTypes(rowTypes)

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

        let cityName = CityHelper.cityName(watchDelegate.wrapper.city!)
        self.cityLabel.setText(cityName)

        lastRefreshLabel.setHidden(false)
        lastRefreshLabel.setText(WeatherHelper.getRefreshTime(watchDelegate.wrapper))

        #if DEBUG
            print("refreshDisplay for " + cityName)
        #endif

        updatedDate = watchDelegate.wrapper.lastRefresh

        #if ENABLE_PWS
        let city = watchDelegate.wrapper.city
        DispatchQueue.global(qos: .userInitiated).async {
            let pws = Self.fetchPWSSync(for: city)
            if let pwsTemp = pws.temperature {
                DispatchQueue.main.async {
                    if let controller = self.weatherTable.rowController(at: 0) as? CurrentWeatherRowController {
                        controller.pwsTemperature = pwsTemp
                        controller.currentTemperatureLabel.setText("Currently".localized() + " " + String(pwsTemp) + "°")
                    }
                    self.cityLabel.setText(pws.stationName ?? cityName)
                }
            }
        }
        #endif
    }
    
    func clearTable() {
        rowTypes = [String]()
        weatherTable.setRowTypes(rowTypes)
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
            self.didSayCityName(result)
        })
    }
    
    @objc func francaisSelected() {
        PreferenceHelper.saveLanguage(Language.French)
        ExtensionDelegateHelper.resetWeather()
        loadData(showError:false)
    }
    
    @objc func englishSelected() {
        PreferenceHelper.saveLanguage(Language.English)
        ExtensionDelegateHelper.resetWeather()
        loadData(showError:false)
    }
    
    
    @objc func addCitySelected() {
        selectCity()
    }
    
    @objc func refresh(showError:Bool) {
        rowTypes = [String]()
        ExtensionDelegateHelper.resetWeather()
        loadData(showError:showError)
    }
    
    func didSayCityName(_ result: [Any]?) {
        if let result = result, let choice = result[0] as? String {
            var match = false;
            PreferenceHelper.getFavoriteCities().forEach({
                let name = CityHelper.cityName($0) + ", " + $0.province.uppercased()
                if name == choice {
                    var refresh = true
                    let selectedCity = PreferenceHelper.getSelectedCity()
                        if selectedCity.id == $0.id {
                            refresh = false
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
        #if DEBUG
            print("cityDidChange")
        #endif
        
        lastRefreshLabel.setHidden(true)
        clearTable()
        locationErrorLabel.setText("")
        
        if LocationServices.isUseCurrentLocation(city) {
            #if DEBUG
                print("cityDidChange Locating")
            #endif
            
            selectCityButton.setHidden(true)
            locatingImage.setHidden(false)
            cityLabel.setText("Locating".localized())
            
            locationServices?.start()
            locationServices?.updateCity(city)
        } else {
            #if DEBUG
                print("cityDidChange Loading")
            #endif
            
            locatingImage.setHidden(true)
            cityLabel.setText("Loading".localized())
            
            PreferenceHelper.saveSelectedCity(city)
            
            locationServices?.cityHasBeenUpdated(city)
        }
        
        PreferenceHelper.addFavorite(city)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        #if DEBUG
            print("Watch urlSession didFinishDownloadingTo")
        #endif
        
        if !LocationServices.isUseCurrentLocation(PreferenceHelper.getCityToUse()) {
            do {
                let jsonData = try Data(contentsOf: location)
                ExtensionDelegateHelper.setWrapper(WeatherHelper.getWeatherInformationsNoCache(jsonData, city: PreferenceHelper.getCityToUse()))
                
                #if DEBUG
                    print("Watch wrapper updated")
                #endif
                
                ExtensionDelegateHelper.updateComplication()
                ExtensionDelegateHelper.scheduleRefresh(Constants.backgroundRefreshInSeconds)

                refreshDisplay()
            } catch {
                print("Error info: \(error)")
            }
        } else {
            print("Watch urlSession didFinishDownloadingTo - no selected city")
        }
    }
    
    func cityHasBeenUpdated(_ city: City) {
        ExtensionDelegateHelper.launchURLSessionNow(self)
    }
    
    func getAllCityList() -> [City] {
        return CityHelper.loadAllCities()
    }
    
    func unknownCity(_ cityName:String) {
        error("The iPhone detected that you are located in".localized() + " " + cityName + ", " + "but this city is not in the Environment Canada list. Do you want to select a city yourself?")
    }
    
    func notInCanada(_ country:String) {
        #if DEBUG
            print("notInCanada")
        #endif
        
        error("The iPhone detected that you are not located in Canada".localized())
    }
    
    func errorLocating(_ errorCode:Int) {
        error("Unable to detect your current location".localized())
    }
    
    func error(_ message:String) {
        locatingCompleted()
        locationErrorLabel.setHidden(false)
        locationErrorLabel.setText(message)
        clearTable()
    }
    
    func locationNotAvailable() {
        refresh(showError:false)
    }
    
    func locatingCompleted() {
        #if DEBUG
            print("locatingCompleted")
        #endif
        
        locatingImage.setHidden(true)
        selectCityButton.setHidden(false)
    }
    
    func locationSameCity() {
        refreshDisplay()
    }

    #if ENABLE_PWS
    static func fetchPWSSync(for city: City?) -> (temperature: Int?, stationName: String?) {
        guard let city = city else { return (nil, nil) }

        let stations = PreferenceHelper.getPWSStations()
        guard !stations.isEmpty,
              PreferenceHelper.hasPWSCredentials(),
              let cityLat = Double(city.latitude),
              let cityLon = Double(city.longitude),
              let apiKey = PreferenceHelper.getPWSApiKey() else {
            return (nil, nil)
        }

        let cityLocation = CLLocation(latitude: cityLat, longitude: cityLon)

        for station in stations {
            let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
            let distance = cityLocation.distance(from: stationLocation)
            guard distance < 50_000 else { continue }

            let urlString = "https://api.weather.com/v2/pws/observations/current?stationId=\(station.stationId)&format=json&units=e&apiKey=\(apiKey)"
            guard let url = URL(string: urlString),
                  let data = try? Data(contentsOf: url),
                  let response = try? JSONDecoder().decode(WUResponse.self, from: data),
                  let observation = response.observations?.first,
                  let tempC = observation.tempC else { continue }

            return (Int(tempC.rounded()), station.name)
        }

        return (nil, nil)
    }
    #endif
}
