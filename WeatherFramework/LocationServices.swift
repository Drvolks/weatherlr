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
    var errorCount = 0
    var locations:[LocatedCity]?
    var serviceActive = false
    
    func start() {
        #if DEBUG
            print("start")
        #endif
        locationManager = CLLocationManager()
        locationManager!.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager!.distanceFilter = 5000 // 5 km
        locationManager!.delegate = self
        
        updateCity(PreferenceHelper.getSelectedCity())
    }
    
    func updateCity(_ cityToUse:City) {
        #if DEBUG
            print("updateCity")
        #endif
        
            if LocationServices.isUseCurrentLocation(cityToUse) {
                #if DEBUG
                    print("updateCity " + cityToUse.frenchName)
                #endif
                
                serviceActive = true
                getCurrentLocation()
            } else {
                #if DEBUG
                    print("updateCity " + cityToUse.frenchName)
                #endif

                serviceActive = false
                cityHasBeenUpdated(cityToUse)
            }
    }
    
    func cityHasBeenUpdated(_ city:City) {
        PreferenceHelper.saveLastLocatedCity(city)
        delegate!.cityHasBeenUpdated(city)
    }
        
    static func isUseCurrentLocation(_ city:City) -> Bool {
        return city.id == Global.currentLocationCityId
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        #if DEBUG
            print("didUpdateLocations")
        #endif
        
        guard let mostRecentLocation = manager.location else {
            errorCount = errorCount + 1
            if(errorCount < 3) {
                getCurrentLocation()
            } else {
                errorCount = 0
                delegate!.errorLocating(6)
            }
            return
        }
        
        errorCount = 0
        
        #if DEBUG
            print(mostRecentLocation)
        #endif
        
        getAdressLocalData(mostRecentLocation)
    }
    
    func getAdressLocalData(_ location: CLLocation) {
        #if DEBUG
            print("getAdressLocalData called")
        #endif
        
        if locations == nil {
            buildLocations()
        }
        
        if let closestLocation = locations!.min(by: { location.distance(from: $0.location) < location.distance(from: $1.location) }) {
            print("closest location: \(closestLocation.city.frenchName), distance: \(location.distance(from: closestLocation.location))")
            if closestLocation.city.id != PreferenceHelper.getCityToUse().id {
                cityHasBeenUpdated(closestLocation.city)
            }
        } else {
            print("coordinates is empty")
            delegate!.errorLocating(5)
        }
    }
    
    func buildLocations() {
        #if DEBUG
            print("buildLocations called")
        #endif
        
        let cities = getAllCityList()
        locations = [LocatedCity]()
        
        for i in 0..<cities.count {
            if cities[i].latitude != "" && cities[i].longitude != "" {
                let clLatitude = CLLocationDegrees(cities[i].latitude)
                let clLongitude = CLLocationDegrees(cities[i].longitude)
                let location = CLLocation(latitude: clLatitude!, longitude: clLongitude!)
                let localCity = LocatedCity(city: cities[i], location: location)
                
                locations?.append(localCity)
            }
        }
        
        #if DEBUG
        print("buildLocations with \(String(describing: locations?.count)) cities having a location")
        #endif
    }
    
    func getAllCityList() -> [City] {
        if allCityList == nil {
            allCityList = delegate!.getAllCityList()
        }
        
        return allCityList!
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("CL failed: \(error)")
        
        errorCount = errorCount + 1
        
        if(errorCount < 3) {
            getCurrentLocation()
        } else {
            errorCount = 0
            delegate!.errorLocating(1)
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
        #if os(watchOS)
            locationManager!.requestAlwaysAuthorization()
        #else
            locationManager!.requestWhenInUseAuthorization()
        #endif
    }
    
    func handleLocationServicesStateUnavailable()
    {
        #if DEBUG
        print("handleLocationServicesStateUnavailable")
        #endif
        
        //TODO Ask user to change the settings through a pop up.
    }
    
    func refreshLocation() {
        if serviceActive {
            handleLocationServicesStateAvailable()
        }
    }
    
    func handleLocationServicesStateAvailable()
    {
        #if DEBUG
        print("handleLocationServicesStateAvailable")
        #endif
        
        locationManager?.requestLocation()
    }
    
    func closestLocation(locations: [CLLocation], closestToLocation location: CLLocation) -> CLLocation? {
        if let closestLocation = locations.min(by: { location.distance(from: $0) < location.distance(from: $1) }) {
            print("closest location: \(closestLocation), distance: \(location.distance(from: closestLocation))")
            return closestLocation
        } else {
            print("coordinates is empty")
            return nil
        }
    }
}
