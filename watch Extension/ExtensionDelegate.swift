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
    
    override init() {
        super.init()
        
        WKExtension.shared().delegate = self
    }
    
    func applicationDidFinishLaunching() {

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
            if (WKExtension.shared().applicationState == .background) {
                if task is WKApplicationRefreshBackgroundTask {
                    scheduleURLSession()
                }
            }
            else if let snapshotTask = task as? WKSnapshotRefreshBackgroundTask {
                completeSnapshotTask(task: snapshotTask)
            }
            
            task.setTaskCompleted()
        }
    }
    
    func scheduleSnapshot() {
        let fireDate = Date()
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: fireDate, userInfo: nil) { (error: Error?) in
            if let error = error {
                print("Error occurred while scheduling background refresh: \(error.localizedDescription)")
            }
        }
    }
    
    
    func scheduleURLSession() {
        if let city = PreferenceHelper.getSelectedCity() {
            scheduleRefresh()
            
            let url = URL(string:UrlHelper.getUrl(city))!
            
            let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: Constants.backgroundDownloadTaskName)
            let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue:nil)
            
            let downloadTask = backgroundSession.downloadTask(with: url)
            downloadTask.resume()
        }
    }
    
    
    func launchURLSession() {
        if let city = PreferenceHelper.getSelectedCity() {
            scheduleRefresh()
            
            let url = URL(string:UrlHelper.getUrl(city))!
            
            let configObject = URLSessionConfiguration.default
            let session = URLSession(configuration: configObject, delegate: self, delegateQueue:nil)

            let downloadTask = session.downloadTask(with: url)
            downloadTask.resume()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        scheduleRefresh()
        
        if let city = PreferenceHelper.getSelectedCity() {
            do {
                let xmlData = try Data(contentsOf: location)
                wrapper = WeatherHelper.getWeatherInformationsNoCache(xmlData, city: city)
                
                if let controller = WKExtension.shared().rootInterfaceController as? InterfaceController {
                    controller.refreshDisplay()
                }
            } catch {
                print("error urlSession when loading data at ", location)
            }
        }
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Error occurred while scheduling background refresh: \(error.localizedDescription)")
        }
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
                complicationServer.reloadTimeline(for: complication)
            }
        }
    }
    
    func scheduleRefresh() {
        let fireDate = Date(timeIntervalSinceNow: Constants.backgroundRefreshInSeconds)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: String(describing: Language.French))
        dateFormatter.timeStyle = .short
        let fireDateStr = dateFormatter.string(from: fireDate)
        
        let userInfo = ["reason" : "background update " + fireDateStr] as NSDictionary
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error: Error?) in
            if let error = error {
                print("Error occurred while scheduling background refresh: \(error.localizedDescription)")
            }
        }
    }
}
