//
//  LocationService.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 18-03-31.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import MapKit

class LocationService : NSObject, CLLocationManagerDelegate {
    var delegate:URLSessionDelegate
    var locationManager : CLLocationManager?
    var allCityList = [City]()
    
    init(_ delegate:URLSessionDelegate) {
        self.delegate = delegate
    }
    
    func start() {
        locationManager = CLLocationManager()
        locationManager!.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager!.delegate = self
        
        if let city = getCurrentCity() {
            #if DEBUG
                print("LocationService started and city requested: " + city.frenchName)
            #endif
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        #if DEBUG
        print("didUpdateLocations")
        #endif
        
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
                #endif
                
                if let cityName = placeMark.locality  {
                    //TODO if let country = placeMark.country
                    #if DEBUG
                    print("reverseGeocodeLocation found city " + cityName)
                    #endif
                    
                    if self.allCityList.count == 0 {
                        let path = Bundle.main.path(forResource: "Cities", ofType: "plist")
                        self.allCityList = (NSKeyedUnarchiver.unarchiveObject(withFile: path!) as? [City])!
                    }
                    
                    if let cityFound = CityHelper.searchSingleCity(cityName, allCityList: self.allCityList) {
                        #if DEBUG
                        print("reverseGeocodeLocation matched city.")
                        #endif
                        
                        ExtensionDelegateHelper.setActiveCity(cityFound)
                        
                        ExtensionDelegateHelper.launchURLSessionNow(self.delegate)
                    }
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("CL failed: \(error)")
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
        
        locationManager?.requestLocation()
    }
    
    func getCurrentCity() -> City? {
        if let city = ExtensionDelegateHelper.getActiveCity() {
            if city.id != Global.currentLocationCityId && !ExtensionDelegateHelper.refreshNeeded() {
                #if DEBUG
                    print("getCurrentCity - city already found and weather not expired")
                #endif
                return city
            }
        }
        
        if let city = PreferenceHelper.getSelectedCity() {
            if city.id == Global.currentLocationCityId {
                getCurrentLocation()
                
                ExtensionDelegateHelper.setActiveCity(city)
                return city
            } else {
                ExtensionDelegateHelper.setActiveCity(city)
                return city
            }
        }
        
        ExtensionDelegateHelper.setActiveCity(nil)
        return nil
    }
}
