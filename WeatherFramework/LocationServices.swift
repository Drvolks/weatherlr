//
//  LocationServices.swift
//  WeatherFramework
//
//  Created by drvolks on 18-03-30.
//  Copyright © 2018 drvolks. All rights reserved.
//

import Foundation
import MapKit

class LocationServices {
    let locManager = CLLocationManager()
    
    let authStatus = CLLocationManager.authorizationStatus()
    let inUse = CLAuthorizationStatus.authorizedWhenInUse
    let always = CLAuthorizationStatus.authorizedAlways
    
    func getAdress(completion: @escaping (_ address: LocationData?, _ error: Error?) -> ()) {
        
        self.locManager.requestWhenInUseAuthorization()
        
        if self.authStatus == inUse || self.authStatus == always {
            if let currentLocation = locManager.location {
                let geoCoder = CLGeocoder()
                
                geoCoder.reverseGeocodeLocation(currentLocation) { placemarks, error in
                    var data:LocationData?
                    
                    if let e = error {
                        completion(nil, e)
                    } else {
                        var placeMark: CLPlacemark!
                        placeMark = placemarks?[0]
                        
                        
                        if let cityName = placeMark.locality  {
                            data = LocationData(cityName: cityName)
                            
                            if let country = placeMark.country {
                                data!.country = country
                            }
                        }
                        
                        completion(data, nil)
                    }
                }
            }
        }
    }
    
}
