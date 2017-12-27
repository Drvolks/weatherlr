//
//  ExtensionDelegate.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, URLSessionDelegate, URLSessionDownloadDelegate  {
    var wrapper = WeatherInformationWrapper()
    let urlSessionConfig = URLSessionConfiguration.background(withIdentifier: Constants.backgroundDownloadTaskName)
    var urlSession:URLSession!
    
    override init() {
        super.init()
        WKExtension.shared().delegate = self
    }
    
    func applicationDidFinishLaunching() {
        #if DEBUG
            print("creating urlSession")
        #endif
        urlSession = URLSession(configuration: urlSessionConfig, delegate: self, delegateQueue: nil)
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
            } else if let task = task as? WKSnapshotRefreshBackgroundTask {
                //updateApplication()
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
        
        if let city = PreferenceHelper.getSelectedCity() {
            let url = URL(string:UrlHelper.getUrl(city))!
            
            let downloadTask = urlSession.downloadTask(with: url)
            downloadTask.resume()
            
            #if DEBUG
                print("downloadTask fired")
            #endif
        } else {
            print("scheduleURLSession - no selected city")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        #if DEBUG
            print("urlSession didFinishDownloadingTo")
        #endif
        
        if let city = PreferenceHelper.getSelectedCity() {
            do {
                let xmlData = try Data(contentsOf: location)
                wrapper = WeatherHelper.getWeatherInformationsNoCache(xmlData, city: city)
                
                #if DEBUG
                    print("wrapper updated")
                #endif
                
                updateComplication()
            } catch {
                print("Error info: \(error)")
            }
        } else {
            print("urlSession didFinishDownloadingTo - no selected city")
        }
        
        scheduleRefresh(Constants.backgroundRefreshInSeconds)
    }
    
    func updateComplication() {
        #if DEBUG
            print("updateComplication")
        #endif
        
        let complicationServer = CLKComplicationServer.sharedInstance()
        if let complications = complicationServer.activeComplications {
            for complication in complications {
                complicationServer.reloadTimeline(for: complication)
            }
        }
    }
}
