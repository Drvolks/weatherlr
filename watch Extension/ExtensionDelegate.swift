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
    var backgroundConfigObject:URLSessionConfiguration!
    var backgroundSession:URLSession!
    
    override init() {
        super.init()
        
        backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: Constants.backgroundDownloadTaskName)
        backgroundSession = URLSession(configuration: backgroundConfigObject!, delegate: self, delegateQueue:nil)
        
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
        #if DEBUG
            print("handle")
        #endif
        
        for task : WKRefreshBackgroundTask in backgroundTasks {
            if (WKExtension.shared().applicationState == .background) {
                if task is WKApplicationRefreshBackgroundTask {
                    scheduleURLSession()
                }
            }
            else if let snapshotTask = task as? WKSnapshotRefreshBackgroundTask {
                completeSnapshotTask(task: snapshotTask)
            }
            
            task.setTaskCompletedWithSnapshot(false)
        }
    }
    
    func scheduleSnapshot() {
        #if DEBUG
            print("scheduleSnapshot")
        #endif
        
        let fireDate = Date()
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: fireDate, userInfo: nil) { (error: Error?) in
            if let error = error {
                print("Error occurred while scheduling background refresh: \(error.localizedDescription)")
            }
        }
    }
    
    
    func scheduleURLSession() {
        #if DEBUG
            print("scheduleURLSession")
        #endif
        
        if let city = PreferenceHelper.getSelectedCity() {
            scheduleRefresh()
            
            let url = URL(string:UrlHelper.getUrl(city))!
            
            let downloadTask = backgroundSession.downloadTask(with: url)
            downloadTask.resume()
        }
    }
    
    
    func launchURLSession() {
        #if DEBUG
            print("launchURLSession")
        #endif
        
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
        #if DEBUG
            print("urlSession1")
        #endif
        
	scheduleRefresh()
	
        if let city = PreferenceHelper.getSelectedCity() {
            do {
                let xmlData = try Data(contentsOf: location)
                wrapper = WeatherHelper.getWeatherInformationsNoCache(xmlData, city: city)
                
                if let controller = WKExtension.shared().rootInterfaceController as? InterfaceController {
                    #if DEBUG
                        print("refreshDisplay")
                    #endif

                    controller.refreshDisplay()
                }
            } catch {
                print("error urlSession when loading data at ", location)
            }
        }
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        #if DEBUG
            print("urlSession2")
        #endif
        
        if let error = error {
            print("Error occurred while scheduling background refresh: \(error.localizedDescription)")
        }
    }
    
    func completeSnapshotTask(task: WKSnapshotRefreshBackgroundTask) {
        #if DEBUG
            print("completeSnapshotTask")
        #endif
        
        let fireDate = Date(timeIntervalSinceNow: Constants.backgroundRefreshInSeconds)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: String(describing: Language.French))
        dateFormatter.timeStyle = .short
        let fireDateStr = dateFormatter.string(from: fireDate)
        
        let userInfo = ["reason" : "snapshot update " + fireDateStr] as NSDictionary
        
        task.setTaskCompleted(restoredDefaultState: false, estimatedSnapshotExpiration: fireDate, userInfo: userInfo)
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
    
    func scheduleRefresh() {
        #if DEBUG
            print("scheduleRefresh")
        #endif
        
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
