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
    var modeBackground = false
    var locations:[LocatedCity]?
    
    func start() {
        #if DEBUG
            print("start")
        #endif
        locationManager = CLLocationManager()
        locationManager!.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager!.distanceFilter = 10000 // 10 km
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
                
                if modeBackground {
                    modeBackground = false
                    locationManager?.stopUpdatingLocation()
                }
                
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
        
        guard let mostRecentLocation = manager.location else {
            errorCount = errorCount + 1
            if(errorCount < 3) {
                getCurrentLocation()
            } else {
                errorCount = 0
                currentCity = nil
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
                
                self.currentCity = nil
                self.delegate!.errorLocating(3)
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
                    self.currentCity = nil
                    self.delegate!.notInCanada()
                    return
                }
                
                var cityName:String?
                if let val = placeMark.locality  {
                    cityName = val
                } else if let val = placeMark.subLocality {
                    cityName = val.replacingOccurrences(of: ", Unorganized", with: "")
                }
                
                if let cityNameFound = cityName {
                    #if DEBUG
                        print("reverseGeocodeLocation found city " + cityNameFound)
                    #endif

                    var cityFoundInList:City?
                    let cities = CityHelper.searchCity(cityNameFound, allCityList: self.getAllCityList())
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
                            print("startUpdatingLocation")
                        #endif
                        
                        self.modeBackground = true
                        self.locationManager?.startUpdatingLocation()
                        
                        self.currentCity = cityFound
                        self.delegate!.cityHasBeenUpdated(cityFound)
                    } else {
                        self.currentCity = nil
                        self.delegate!.unknownCity(cityNameFound)
                    }
                } else {
                    self.currentCity = nil
                    self.delegate!.errorLocating(2)
                }
            }
        })
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
            currentCity = closestLocation.city
            delegate!.cityHasBeenUpdated(closestLocation.city)
        } else {
            print("coordinates is empty")
            if let city = currentCity {
                if LocationServices.isUseCurrentLocation(city) {
                    currentCity = nil
                }
            }
            delegate!.errorLocating(5)
        }
        
        #if DEBUG
        print("startUpdatingLocation")
        #endif
        
        self.modeBackground = true
        self.locationManager?.startUpdatingLocation()
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
            currentCity = nil
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
        
        if !modeBackground {
            locationManager?.requestLocation()
        }
    }
    
    func getCurrentCity() -> City? {
        return currentCity
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
