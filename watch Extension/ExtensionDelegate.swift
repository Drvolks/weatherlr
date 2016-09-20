//
//  ExtensionDelegate.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2016-07-02.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, URLSessionDownloadDelegate {
    var wrapper = WeatherInformationWrapper()
    
    func applicationDidFinishLaunching() {
        WKExtension.shared().delegate = self
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        print("handle background tasks")
        
        for task : WKRefreshBackgroundTask in backgroundTasks {
            print("received background task: ", task)
            
            if (WKExtension.shared().applicationState == .background) {
                if task is WKApplicationRefreshBackgroundTask {
                    // this task is completed below, our app will then suspend while the download session runs
                    print("application task received, start URL session")
                    scheduleURLSession()
                }
            }
            else if let urlTask = task as? WKURLSessionRefreshBackgroundTask {
                let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: urlTask.sessionIdentifier)
                let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue: nil)
                
                print("Rejoining session ", backgroundSession)
            } else if let snapshotTask = task as? WKSnapshotRefreshBackgroundTask {
                completeSnapshotTask(task: snapshotTask)
            }
            
            task.setTaskCompleted()
        }
    }
    
    func scheduleSnapshot() {
        print("scheduleSnapshot")
        
        let fireDate = Date()
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: fireDate, userInfo: nil) { error in
            if (error == nil) {
                print("successfully scheduled snapshot.")
            } else {
                print("scheduleSnapshot error ", error)
            }
        }
    }
    
    
    func scheduleURLSession() {
        print("scheduleURLSession")
        
        if let city = PreferenceHelper.getSelectedCity() {
            scheduleRefresh()
            
            let url = URL(string:UrlHelper.getUrl(city))!
            
            let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: Constants.backgroundDownloadTaskName)
            //backgroundConfigObject.sessionSendsLaunchEvents = true
            let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue:nil)
            
            print("Download url " + UrlHelper.getUrl(city))
            
            let downloadTask = backgroundSession.downloadTask(with: url)
            downloadTask.resume()
            
            print("downloadTask.resume")
            
        }
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("NSURLSession finished to url: ", location)
        
        scheduleRefresh()
        
        if let city = PreferenceHelper.getSelectedCity() {
            do {
                let xmlData = try Data(contentsOf: location)
                print(xmlData)
                wrapper = WeatherHelper.getWeatherInformationsNoCache(xmlData, city: city)
                
                if let controller = WKExtension.shared().rootInterfaceController as? InterfaceController {
                    print("will now refresh display")
                    controller.refreshDisplay()
                }
            } catch {
                print("error urlSession when loading data at ", location)
            }
        }
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if(error != nil) {
            print("urlSession error", error)
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("urlSessionDidFinishEvents")
    }
    
    func completeSnapshotTask(task: WKSnapshotRefreshBackgroundTask) {
        let fireDate = Date(timeIntervalSinceNow: Constants.backgroundRefreshInSeconds)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: String(describing: Language.French))
        dateFormatter.timeStyle = .short
        let fireDateStr = dateFormatter.string(from: fireDate)
        
        let userInfo = ["reason" : "snapshot update " + fireDateStr] as NSDictionary
        
        task.setTaskCompleted(restoredDefaultState: false, estimatedSnapshotExpiration: fireDate, userInfo: userInfo)
    }
    
    func updateComplication() {
        let complicationServer = CLKComplicationServer.sharedInstance()
        if let complications = complicationServer.activeComplications {
            for complication in complications {
                print("updating complication", complication)
                
                complicationServer.reloadTimeline(for: complication)
            }
        }
    }
    
    func scheduleRefresh() {
        print("scheduleRefresh")
        
        let fireDate = Date(timeIntervalSinceNow: Constants.backgroundRefreshInSeconds)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: String(describing: Language.French))
        dateFormatter.timeStyle = .short
        let fireDateStr = dateFormatter.string(from: fireDate)
        
        let userInfo = ["reason" : "background update " + fireDateStr] as NSDictionary
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error) in
            if (error == nil) {
                print("successfully scheduled background task at ", fireDateStr)
            } else {
                print("scheduleRefresh error ", error)
            }
        }
    }
}
