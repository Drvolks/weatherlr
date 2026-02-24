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

public class LocationServices : NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    public var delegate:LocationServicesDelegate?
    var locationManager : CLLocationManager?
    var locationManagerType = CLLocationManager.self
    var allCityList:[City]?
    var errorCount = 0
    var locations:[LocatedCity]?
    var serviceActive = false
  
    public func start() {
        start(manager: CLLocationManager())
    }
    
    public func start(manager:CLLocationManager) {
        #if DEBUG
            print("start")
        #endif
        locationManager = manager
        locationManagerType = type(of:manager)
        
        // TODO descendre ça à 1km
        locationManager!.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager!.distanceFilter = Global.locationDistance
    }
    
    public func updateCity(_ cityToUse:City) {
        #if DEBUG
            print("updateCity")
        #endif
        
        if LocationServices.isUseCurrentLocation(cityToUse) {
            #if DEBUG
                print("updateCity localisation")
            #endif
                
            enableLocation()
            getCurrentLocation()
        } else {
            #if DEBUG
                print("updateCity " + cityToUse.frenchName)
            #endif

            disableLocation()
            cityHasBeenUpdated(cityToUse)
        }
    }
    
    public func cityHasBeenUpdated(_ city:City) {
        PreferenceHelper.saveLastLocatedCity(city)
        delegate!.cityHasBeenUpdated(city)
    }
        
    public static func isUseCurrentLocation(_ city:City) -> Bool {
        return city.id == Global.currentLocationCityId
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
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
                delegate!.errorLocating(LocationErrors.TooManyErrors)
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
    }
    
    func getClosestLocation(_ location: CLLocation) -> LocatedCity? {
        if locations == nil {
            buildLocations()
        }
        
        if let closestLocation = locations!.min(by: { location.distance(from: $0.location) < location.distance(from: $1.location) }) {
            print("closest location: \(closestLocation.city.frenchName), distance: \(location.distance(from: closestLocation.location))")
            if location.distance(from: closestLocation.location) < Global.currentLocationMaxDistance {
                return closestLocation
            } else {
                #if DEBUG
                    print("coordinates is too far")
                #endif
            }
        }
        
        return nil
    }
    
    func buildLocations() {
        #if DEBUG
            print("buildLocations called")
        #endif
        
        let cities = getAllCityList()
        locations = [LocatedCity]()
        
        for i in 0..<cities.count {
            if shouldUseCityForLocation(city: cities[i]) {
                let localCity = buildLocation(city: cities[i])
                locations?.append(localCity)
            }
        }
        
        #if DEBUG
            print("buildLocations with \(String(describing: locations?.count)) cities having a location")
        #endif
    }
    
    func shouldUseCityForLocation(city:City) -> Bool {
        return !city.latitude.isEmpty && !city.longitude.isEmpty && city.latitude.isDouble && city.longitude.isDouble
    }
    
    func buildLocation(city:City) -> LocatedCity {
        let clLatitude = CLLocationDegrees(city.latitude)
        let clLongitude = CLLocationDegrees(city.longitude)
        let location = CLLocation(latitude: clLatitude!, longitude: clLongitude!)
        return LocatedCity(city: city, location: location)
    }
    
    public func getAllCityList() -> [City] {
        if allCityList == nil {
            allCityList = delegate!.getAllCityList()
        }
        
        return allCityList!
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
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
        
        handleLocationServicesAuthorizationStatus(status: locationManager!.authorizationStatus)
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
                disableLocation()
                if(LocationServices.isUseCurrentLocation(PreferenceHelper.getSelectedCity())) {
                    delegate!.locationNotAvailable()
                }
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
        
            @unknown default:
                print("Unknown status from handleLocationServicesAuthorizationStatus")
                break
        }
    }
    
    func disableLocation() {
        serviceActive = false
        if let manager = locationManager {
            manager.delegate = nil
        }
    }
    
    func enableLocation() {
        serviceActive = true
        if let manager = locationManager {
            manager.delegate = self
        }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        #if DEBUG
            print("locationManager didChangeAuthorization")
        #endif

        handleLocationServicesAuthorizationStatus(status: manager.authorizationStatus)
    }
    
    func escalateLocationServiceAuthorization() {
        // Escalate only when the authorization is set to when-in-use
        if locationManager!.authorizationStatus == .authorizedWhenInUse {
            locationManager!.requestAlwaysAuthorization()
        }
    }
    
    public func refreshLocation() {
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
    
    func getAdressAndValidateCanada(_ location: CLLocation) {
        #if DEBUG
            print("getAdressAndValidateCanada called")
        #endif

        let coordinate = location.coordinate
        reverseGeocode(coordinate: coordinate) { [weak self] country in
            guard let country = country else { return }
            if country != "Canada" {
                self?.disableLocation()
                PreferenceHelper.switchFavoriteCity(cityId: Global.currentLocationCityId)
                PreferenceHelper.removeLastLocatedCity()
                self?.delegate?.notInCanada(country)
                return
            }

            self?.handleCanadianAddress(location)
        }
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D, completion: @escaping @Sendable (String?) -> Void) {
        Task {
            do {
                let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                guard let request = MKReverseGeocodingRequest(location: loc) else {
                    completion(nil)
                    return
                }
                let mapItems = try await request.mapItems
                let country = mapItems.first?.addressRepresentations?.regionName

                #if DEBUG
                print("reverseGeocodeLocation completed")
                if let addressRep = mapItems.first?.addressRepresentations {
                    print("regionName: \(addressRep.regionName ?? "nil")")
                    print("cityName: \(addressRep.cityName ?? "nil")")
                    print("cityWithContext: \(addressRep.cityWithContext ?? "nil")")
                    print("fullAddress: \(addressRep.fullAddress(includingRegion: true, singleLine: true) ?? "nil")")
                }
                #endif

                DispatchQueue.main.async { completion(country) }
            } catch {
                #if DEBUG
                    print("reverseGeocodeLocation error")
                    print(error)
                #endif
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    func handleCanadianAddress(_ location: CLLocation) {
        if let closestLocation = getClosestLocation(location) {
            print("closest location: \(closestLocation.city.frenchName), distance: \(location.distance(from: closestLocation.location))")
            
            delegate!.locatingCompleted()
            
            if closestLocation.city.id != PreferenceHelper.getCityToUse().id {
                cityHasBeenUpdated(closestLocation.city)
            } else {
                delegate!.locationSameCity()
            }
        } else {
            #if DEBUG
                print("coordinates is empty or too far")
            #endif
            delegate!.errorLocating(LocationErrors.LocationTooFarOrEmpty)
        }
    }
}
