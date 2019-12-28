//
//  ExtensionDelegate.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import WatchKit
import WeatherFramework

class ExtensionDelegate: NSObject, WKExtensionDelegate, URLSessionDelegate, URLSessionDownloadDelegate  {
    var wrapper = WeatherInformationWrapper()
    let urlSessionConfig = URLSessionConfiguration.background(withIdentifier: Constants.backgroundDownloadTaskName)
    var savedTask:WKRefreshBackgroundTask?
    
    override init() {
        super.init()
    }
    
    func applicationDidFinishLaunching() {
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
            scheduleRefresh(Constants.backgroundRefreshInSeconds)
        }
    }
    
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        #if DEBUG
            print("urlSession didFinishDownloadingTo")
        #endif
        
        let city = PreferenceHelper.getCityToUse()
        if !LocationServices.isUseCurrentLocation(city) {
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
