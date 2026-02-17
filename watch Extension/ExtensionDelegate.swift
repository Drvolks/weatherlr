//
//  ExtensionDelegate.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, @preconcurrency URLSessionDelegate, @preconcurrency URLSessionDownloadDelegate, @preconcurrency WCSessionDelegate  {
    var wrapper = WeatherInformationWrapper()
    let urlSessionConfig = URLSessionConfiguration.background(withIdentifier: Constants.backgroundDownloadTaskName)
    var savedTask:WKRefreshBackgroundTask?
    
    override init() {
        super.init()
    }
    
    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
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
                launchURLSession()
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
    
    func launchURLSession() {
        #if DEBUG
            print("launchURLSession")
        #endif
        
        let city = PreferenceHelper.getCityToUse()
        if !LocationServices.isUseCurrentLocation(city) {
            let url = URL(string:UrlHelper.getUrl(city))!
                
            let urlSession = URLSession(configuration: urlSessionConfig, delegate: self, delegateQueue: nil)
            let downloadTask = urlSession.downloadTask(with: url)
            downloadTask.resume()
                
            #if DEBUG
                print("downloadTask fired")
            #endif
        } else {
            print("scheduleURLSession - no selected city")
            ExtensionDelegateHelper.scheduleRefresh(Constants.backgroundRefreshInSeconds)
        }
    }
    
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        #if DEBUG
            print("urlSession didFinishDownloadingTo")
        #endif
        
        let city = PreferenceHelper.getCityToUse()
        if !LocationServices.isUseCurrentLocation(city) {
            do {
                let jsonData = try Data(contentsOf: location)
                wrapper = WeatherHelper.getWeatherInformationsNoCache(jsonData, city: city)
                
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
            #if DEBUG
                print("urlSession didFinishDownloadingTo - no selected city")
            #endif
        }
        
        if let task = savedTask {
            task.setTaskCompletedWithSnapshot(true)
            savedTask = nil
            
            #if DEBUG
                print("savedTask comleted")
            #endif
        }
            
        ExtensionDelegateHelper.scheduleRefresh(Constants.backgroundRefreshInSeconds)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        #if DEBUG
            print("urlSession didCompleteWithError")
        #endif

        if let error = error {
            print(error)
            // Retry after 5 minutes on failure instead of silently stopping
            ExtensionDelegateHelper.scheduleRefresh(5.0 * 60.0)
        }

        if let task = savedTask {
            task.setTaskCompletedWithSnapshot(true)
            savedTask = nil

            #if DEBUG
                print("savedTask comleted in didCompleteWithError")
            #endif
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if DEBUG
            print("WCSession activation: \(activationState.rawValue)")
        #endif
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        #if DEBUG
            print("Received applicationContext from iPhone")
        #endif

        let defaults = UserDefaults(suiteName: Global.SettingGroup)!

        if let data = applicationContext[Global.selectedCityKey] as? Data {
            defaults.set(data, forKey: Global.selectedCityKey)
        }
        if let data = applicationContext[Global.favotiteCitiesKey] as? Data {
            defaults.set(data, forKey: Global.favotiteCitiesKey)
        }
        if let lang = applicationContext[Global.languageKey] as? String {
            defaults.set(lang, forKey: Global.languageKey)
        }
        if let data = applicationContext[Global.lastLocatedCityKey] as? Data {
            defaults.set(data, forKey: Global.lastLocatedCityKey)
        }

        #if ENABLE_PWS
        if let data = applicationContext[Global.pwsStationsKey] as? Data {
            defaults.set(data, forKey: Global.pwsStationsKey)
        }
        if let apiKey = applicationContext["pwsApiKey"] as? String {
            defaults.set(apiKey, forKey: "pwsApiKey")
        }
        #endif

        WeatherHelper.cache.removeAllObjects()
    }
}
