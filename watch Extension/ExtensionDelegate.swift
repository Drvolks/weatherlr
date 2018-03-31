//
//  ExtensionDelegate.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import WatchKit
import MapKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, URLSessionDelegate, URLSessionDownloadDelegate, CLLocationManagerDelegate  {
    var wrapper = WeatherInformationWrapper()
    let urlSessionConfig = URLSessionConfiguration.background(withIdentifier: Constants.backgroundDownloadTaskName)
    var savedTask:WKRefreshBackgroundTask?
    var locationManager : CLLocationManager?
    var selectedCity:City?
    var allCityList = [City]()
    
    override init() {
        super.init()
        WKExtension.shared().delegate = self
    }
    
    func applicationDidFinishLaunching() {
        locationManager = CLLocationManager()
        locationManager!.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager!.delegate = self
        
        if let city = PreferenceHelper.getSelectedCity() {
            if city.id == Global.currentLocationCityId {
               // locationManager!.startUpdatingLocation()
            }
        }
    }

    func applicationDidBecomeActive() {
        
    }

    func applicationWillResignActive() {
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        #if DEBUG
            print("handle")
        #endif
        
        for task in backgroundTasks {
            #if DEBUG
                print(task)
            #endif

            if let task = task as? WKApplicationRefreshBackgroundTask {
                if getCurrentCity() != nil {
                    launchURLSession()
                }
                task.setTaskCompletedWithSnapshot(false)
            } else if let task = task as? WKURLSessionRefreshBackgroundTask {
                savedTask = task
                    
                #if DEBUG
                    print("savedTask initialized")
                #endif
            } else if let task = task as? WKSnapshotRefreshBackgroundTask {
                if savedTask == nil && ExtensionDelegateHelper.refreshNeeded() {
                    #if DEBUG
                        print("WKSnapshotRefreshBackgroundTask without any background refresh task in progress, creating one")
                    #endif
                    
                    launchURLSession()
                }
            
                task.setTaskCompletedWithSnapshot(true)
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func scheduleRefresh(_ backgroundRefreshInSeconds: Double) {
        #if DEBUG
            print("scheduleRefresh")
        #endif
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: backgroundRefreshInSeconds), userInfo: nil) { (error: Error?) in
            if let error = error {
                print("Error occured while scheduling background refresh: \(error.localizedDescription)")
            }
        }
    }
    
    func launchURLSession() {
        #if DEBUG
            print("launchURLSession")
        #endif
        
        if let city = selectedCity {
            if city.id == Global.currentLocationCityId {
                // recherche de l'emplecement en cours
                
            } else {
                let url = URL(string:UrlHelper.getUrl(city))!
                
                let urlSession = URLSession(configuration: urlSessionConfig, delegate: self, delegateQueue: nil)
                let downloadTask = urlSession.downloadTask(with: url)
                downloadTask.resume()
                
                #if DEBUG
                    print("downloadTask fired")
                #endif
            }
        } else {
            print("scheduleURLSession - no selected city")
        }
    }
    
    func getCurrentCity() -> City? {
        if let city = PreferenceHelper.getSelectedCity() {
            if city.id == Global.currentLocationCityId {
                getCurrentLocation()
                
                self.selectedCity = city
                return self.selectedCity
            } else {
                selectedCity = city
                return selectedCity
            }
        }
        
        selectedCity = nil
        return selectedCity
    }
    
    func getCurrentLocation()
    {
        #if DEBUG
            print("getCurrentLocation")
        #endif
        CLLocationManager.authorizationStatus()
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
            print("handleLocationServicesStateNotDetermined")
        #endif
        
        locationManager?.requestAlwaysAuthorization()
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        handleLocationServicesAuthorizationStatus(status: status)
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
        let geoCoder = CLGeocoder()
        
        #if DEBUG
            print("reverseGeocodeLocation called")
        #endif
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
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
                
                if let cityName = placeMark.locality  {
                    //TODO if let country = placeMark.country
                    
                    if self.allCityList.count == 0 {
                        let path = Bundle.main.path(forResource: "Cities", ofType: "plist")
                        self.allCityList = (NSKeyedUnarchiver.unarchiveObject(withFile: path!) as? [City])!
                    }
                    
                    if let cityFound = CityHelper.searchSingleCity(cityName, allCityList: self.allCityList) {
                        self.selectedCity = cityFound
                        ExtensionDelegateHelper.launchURLSessionNow(self)
                    }
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("CL failed: \(error)")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        #if DEBUG
            print("urlSession didFinishDownloadingTo")
        #endif
        
        if let city = selectedCity {
            do {
                let xmlData = try Data(contentsOf: location)
                wrapper = WeatherHelper.getWeatherInformationsNoCache(xmlData, city: city)
                
                #if DEBUG
                    print("wrapper updated")
                #endif
                
                ExtensionDelegateHelper.updateComplication()
            } catch {
                print("Error info: \(error)")
                // plan b
                ExtensionDelegateHelper.launchURLSessionNow(self)
            }
        } else {
            print("urlSession didFinishDownloadingTo - no selected city")
        }
        
        if let task = savedTask {
            task.setTaskCompletedWithSnapshot(true)
            savedTask = nil
            
            #if DEBUG
                print("savedTask comleted")
            #endif
        }
            
        scheduleRefresh(Constants.backgroundRefreshInSeconds)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        #if DEBUG
            print("urlSession didCompleteWithError")
        #endif
        
        if let error = error {
            print(error)
        }
        
        if let task = savedTask {
            task.setTaskCompletedWithSnapshot(true)
            savedTask = nil
            
            #if DEBUG
                print("savedTask comleted in didCompleteWithError")
            #endif
        }
    }
}
