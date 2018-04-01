//
//  LocationServices.swift
//  WeatherFramework
//
//  Created by Jean-Francois Dufour on 18-04-01.
//  Copyright © 2018 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import MapKit

class LocationServices : NSObject, CLLocationManagerDelegate {
    var delegate:LocationServicesDelegate?
    var locationManager : CLLocationManager?
    var allCityList:[City]?
    var currentCity:City?
    var errorCount = 0
    
    func start() {
        locationManager = CLLocationManager()
        locationManager!.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager!.distanceFilter = 1000
        locationManager!.delegate = self
        
        updateCity(PreferenceHelper.getSelectedCity())
    }
    
    func updateCity(_ cityToUse:City?) {
        currentCity = nil
        
        if let city = cityToUse {
            if isUseCurrentLocation(city) {
                locationManager?.startUpdatingLocation()
                getCurrentLocation()
            } else {
                locationManager?.stopUpdatingLocation()
                currentCity = city
                self.delegate!.cityHasBeenUpdated(city)
            }
        }
    }
        
    func isUseCurrentLocation(_ city:City) -> Bool {
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
                #endif
                
                if let cityName = placeMark.locality  {
                    //TODO if let country = placeMark.country
                    #if DEBUG
                    print("reverseGeocodeLocation found city " + cityName)
                    #endif

                    if self.allCityList == nil {
                        self.allCityList = self.delegate!.getAllCityList()
                    }
                    
                    if let cityFound = CityHelper.searchSingleCity(cityName, allCityList: self.allCityList!) {
                        #if DEBUG
                            print("reverseGeocodeLocation matched city.")
                        #endif
                        
                        self.currentCity = cityFound
                        self.delegate!.cityHasBeenUpdated(cityFound)
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
