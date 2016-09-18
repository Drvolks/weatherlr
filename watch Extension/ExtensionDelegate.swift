//
//  ExtensionDelegate.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, URLSessionDownloadDelegate {
    static var wrapper = WeatherInformationWrapper()
    
    func applicationDidFinishLaunching() {
        //WKExtension.shared().delegate = self
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task : WKRefreshBackgroundTask in backgroundTasks {
            print("received background task: ", task)
            // only handle these while running in the background
            if (WKExtension.shared().applicationState == .background) {
                if task is WKApplicationRefreshBackgroundTask {
                    // this task is completed below, our app will then suspend while the download session runs
                    print("application task received, start URL session")
                    //scheduleURLSession()
                    
                    getWeather()
                    
                } else if task is WKSnapshotRefreshBackgroundTask {
                    print("WKSnapshotRefreshBackgroundTask")
                }
            }
            else if let urlTask = task as? WKURLSessionRefreshBackgroundTask {
                let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: urlTask.sessionIdentifier)
                let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue: nil)
                
                print("Rejoining session ", backgroundSession)
            }
            // make sure to complete all tasks, even ones you don't handle
            task.setTaskCompleted()
        }
    }
    
    func scheduleSnapshot() {
        // fire now, we're ready
        let fireDate = Date()
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: fireDate, userInfo: nil) { error in
            if (error == nil) {
                print("successfully scheduled snapshot.  All background work completed.")
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("NSURLSession finished to url: ", location)
        
        if let city = PreferenceHelper.getSelectedCity() {
            let xmlData = try! Data(contentsOf: location)
            print(xmlData)
            ExtensionDelegate.wrapper = WeatherHelper.getWeatherInformationsNoCache(xmlData, city: city)
            
            if let controller = WKExtension.shared().rootInterfaceController as? InterfaceController {
                print("will now refresh display")
                controller.refreshDisplay()
                
                scheduleSnapshot()
            }
        }
    }
    
    func scheduleURLSessionxxxxxx() {
        if let city = PreferenceHelper.getSelectedCity() {
            print("scheduleURLSession")
            
            let url = URL(string:UrlHelper.getUrl(city))!
            
            let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: NSUUID().uuidString)
            backgroundConfigObject.sessionSendsLaunchEvents = true
            let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue:nil)
            
            print("Download url " + UrlHelper.getUrl(city))
            
            let downloadTask = backgroundSession.downloadTask(with: url)
            downloadTask.resume()
            
            print("downloadTask.resume")
            
            scheduleRefresh()
        }
    }
    
    func scheduleRefresh() {
        let fireDate = Date(timeIntervalSinceNow: Constants.backgroundRefreshInSeconds)
        let userInfo = ["reason" : "background update"] as NSDictionary
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error) in
            if (error == nil) {
                print("successfully scheduled background task, use the crown to send the app to the background and wait for handle:BackgroundTasks to fire.")
            }
        }
    }
    
    func weatherDidUpdate(_ wrapper: WeatherInformationWrapper) {
        print("weatherDidUpdate")
        
        ExtensionDelegate.wrapper = wrapper
        
        scheduleRefresh()
        scheduleSnapshot()
    }
    
    func getWeather() {
        if let city = PreferenceHelper.getSelectedCity() {
            let url = UrlHelper.getUrl(city)
        
            if let url = URL(string: url) {
                let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                    DispatchQueue.main.async(execute: {
                        if (data != nil && error == nil) {
                            let rssParser = RssParser(xmlData: data!, language: PreferenceHelper.getLanguage())
                            let wrapper = WeatherHelper.generateWeatherInformation(rssParser, city: city)
                        
                            DispatchQueue.main.async {
                                self.weatherDidUpdate(wrapper)
                            }
                        } else {
                            print("ERROR " + error.debugDescription)
                        }
                    })
                }
                task.resume()
            }
        }
    }
}
