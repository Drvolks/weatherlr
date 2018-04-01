//
//  LocationServices.swift
//  WeatherFramework
//
//  Created by Jean-Francois Dufour on 18-04-01.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
//
// Montreal est 45,50884 / -73,58781

import Foundation
import MapKit

class LocationServices : NSObject, CLLocationManagerDelegate {
    var delegate:LocationServicesDelegate?
    var locationManager : CLLocationManager?
    var allCityList:[City]?
    var currentCity:City?
    var errorCount = 0
    
    func start() {
        #if DEBUG
            print("start")
        #endif
        locationManager = CLLocationManager()
        locationManager!.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager!.delegate = self
        
        updateCity(PreferenceHelper.getSelectedCity())
    }
    
    func updateCity(_ cityToUse:City?) {
        currentCity = nil
        
        #if DEBUG
            print("updateCity")
        #endif
        
        if let city = cityToUse {
            if LocationServices.isUseCurrentLocation(city) {
                #if DEBUG
                    print("updateCity " + city.frenchName)
                #endif
                
                getCurrentLocation()
            } else {
                #if DEBUG
                    print("updateCity " + city.frenchName)
                #endif
                
                currentCity = city
                self.delegate!.cityHasBeenUpdated(city)
            }
        }
    }
        
    static func isUseCurrentLocation(_ city:City) -> Bool {
        return city.id == Global.currentLocationCityId
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        #if DEBUG
            print("didUpdateLocations")
        #endif
        
        errorCount = 0
        
        guard let mostRecentLocation = manager.location else { return }
        #if DEBUG
        print(mostRecentLocation)
        #endif
        getAdress(mostRecentLocation)
    }
    
    func getAdress(_ location: CLLocation) {
        #if DEBUG
        print("reverseGeocodeLocation called")
        #endif
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            #if DEBUG
            print("reverseGeocodeLocation completed")
            #endif
            
            if let e = error {
                #if DEBUG
                print("reverseGeocodeLocation error")
                print(e)
                #endif
            } else {
                var placeMark: CLPlacemark!
                placeMark = placemarks?[0]
                
                #if DEBUG
                    print(placeMark)
                    if let val = placeMark.locality {
                        print("locality " + val)
                    }
                
                    if let val = placeMark.name {
                        print("name " + val)
                    }
                
                    if let val = placeMark.country {
                        print("country " + val)
                    }
                
                    if let val = placeMark.postalCode {
                        print("postalCode " + val)
                    }
                
                    if let val = placeMark.administrativeArea {
                        print("administrativeArea " + val)
                    }
                
                    if let val = placeMark.subAdministrativeArea {
                        print("subAdministrativeArea " + val)
                    }
                
                    if let val = placeMark.locality {
                        print("subLocality " + val)
                    }
                
                    if let val = placeMark.subLocality {
                        print("subLocality " + val)
                    }
                #endif
                
                var isCanada = false
                if let country = placeMark.country {
                    if country == "Canada" {
                        isCanada = true
                    }
                }
                
                if !isCanada {
                    self.delegate!.notInCanada()
                    return
                }
                
                var cityName:String?
                if let val = placeMark.locality  {
                    cityName = val
                } else if let val = placeMark.subLocality {
                    cityName = val
                }
                
                if let cityNameFound = cityName {
                    #if DEBUG
                        print("reverseGeocodeLocation found city " + cityNameFound)
                    #endif

                    if self.allCityList == nil {
                        self.allCityList = self.delegate!.getAllCityList()
                    }
                    
                    var cityFoundInList:City?
                    let cities = CityHelper.searchCity(cityNameFound, allCityList: self.allCityList!)
                    for i in 0..<cities.count {
                        let city = cities[i]
                        
                        if let province = placeMark.administrativeArea {
                            if city.province.uppercased() == province.uppercased() {
                                cityFoundInList = city
                                break
                            }
                        } else {
                            cityFoundInList = city
                            break
                        }
                    }
                    
                    if let cityFound = cityFoundInList {
                        #if DEBUG
                            print("reverseGeocodeLocation matched city " + cityFound.frenchName)
                        #endif
                        
                        self.currentCity = cityFound
                        self.delegate!.cityHasBeenUpdated(cityFound)
                    } else {
                        self.currentCity = nil
                        self.delegate!.unknownCity(cityNameFound)
                    }
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("CL failed: \(error)")
        
        errorCount = errorCount + 1
        currentCity = nil
        
        if(errorCount < 10) {
            getCurrentLocation()
        } else {
            // TODO implémenter delegate.locationNonDisponible
        }
    }
    
    func getCurrentLocation()
    {
        #if DEBUG
        print("getCurrentLocation")
        #endif
        handleLocationServicesAuthorizationStatus(status: CLLocationManager.authorizationStatus())
    }
    
    func handleLocationServicesAuthorizationStatus(status: CLAuthorizationStatus)
    {
        #if DEBUG
        print("handleLocationServicesAuthorizationStatus")
        #endif
        
        switch status
        {
        case .notDetermined:
            #if DEBUG
            print("notDetermined")
            #endif
            handleLocationServicesStateNotDetermined()
        case .restricted, .denied:
            #if DEBUG
            print("restricted or denied")
            #endif
            handleLocationServicesStateUnavailable()
        case .authorizedAlways, .authorizedWhenInUse:
            #if DEBUG
            print("authorizedAlways authorizedWhenInUse")
            #endif
            handleLocationServicesStateAvailable()
        }
    }
    
    func handleLocationServicesStateNotDetermined()
    {
        #if DEBUG
        print("handleLocationServicesStateNotDetermined - will request authorization")
        #endif
        
        // TODO debuter par inUse et escalader à always
        
        locationManager!.requestAlwaysAuthorization()
    }
    
    func handleLocationServicesStateUnavailable()
    {
        #if DEBUG
        print("handleLocationServicesStateUnavailable")
        #endif
        
        //TODO Ask user to change the settings through a pop up.
    }
    
    func handleLocationServicesStateAvailable()
    {
        #if DEBUG
        print("handleLocationServicesStateAvailable")
        #endif
        
        currentCity = CityHelper.getCurrentLocationCity()
        locationManager?.requestLocation()
    }
    
}
