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
        
        getAdressAndValidateCanada(location)
        
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
                // Request when-in-use authorization initially
                locationManager!.requestWhenInUseAuthorization()
                break
            
            case .restricted, .denied:
                // Disable location features
                serviceActive = false
                delegate!.locationNotAvailable()
                break
            
            case .authorizedWhenInUse:
                // Enable basic location features
                
                #if os(watchOS)
                    escalateLocationServiceAuthorization()
                #endif
                
                handleLocationServicesStateAvailable()
                break
            
            case .authorizedAlways:
                // Enable any of your app's location features
                handleLocationServicesStateAvailable()
                break
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        #if DEBUG
        print("locationManager didChangeAuthorization")
        #endif
        
        switch status {
            case .restricted, .denied:
                serviceActive = false
                delegate!.locationNotAvailable()
                break
            
            case .authorizedWhenInUse:
                // Enable only your app's when-in-use features.
                
                #if os(watchOS)
                    escalateLocationServiceAuthorization()
                #endif
                
                handleLocationServicesStateAvailable()
                break
            
            case .authorizedAlways:
                // Enable any of your app's location services.
                handleLocationServicesStateAvailable()
                break
            
            case .notDetermined:
                break
        }
    }
    
    func escalateLocationServiceAuthorization() {
        // Escalate only when the authorization is set to when-in-use
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager!.requestAlwaysAuthorization()
        }
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
    
    /*
    func closestLocation(locations: [CLLocation], closestToLocation location: CLLocation) -> CLLocation? {
        if let closestLocation = locations.min(by: { location.distance(from: $0) < location.distance(from: $1) }) {
            print("closest location: \(closestLocation), distance: \(location.distance(from: closestLocation))")
            return closestLocation
        } else {
            print("coordinates is empty")
            return nil
        }
    }
 */
    
    func getAdressAndValidateCanada(_ location: CLLocation) {
        #if DEBUG
            print("getAdressAndValidateCanada called")
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
                    
                    if !isCanada {
                        self.serviceActive = false
                        PreferenceHelper.switchFavoriteCity(cityId: Global.currentLocationCityId)
                        PreferenceHelper.removeLastLocatedCity()
                        self.delegate!.notInCanada(country)
                        return
                    }
                }
            }
        })
    }
}
