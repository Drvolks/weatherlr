//
//  AppDelegate.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2026-02-24.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import WatchKit
import WatchConnectivity

class AppDelegate: NSObject, WKApplicationDelegate {
    let urlSessionConfig = URLSessionConfiguration.background(withIdentifier: Constants.backgroundDownloadTaskName)
    let backgroundSessionDelegate = BackgroundSessionDelegate()
    let wcSessionHandler = WCSessionDelegateHandler()

    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            WCSession.default.delegate = wcSessionHandler
            WCSession.default.activate()
        }
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
                backgroundSessionDelegate.savedTask = task

                #if DEBUG
                    print("savedTask initialized")
                #endif
            } else if let task = task as? WKSnapshotRefreshBackgroundTask {
                if backgroundSessionDelegate.savedTask == nil {
                    Task { @MainActor in
                        if WatchWeatherModel.shared.refreshNeeded() {
                            #if DEBUG
                                print("WKSnapshotRefreshBackgroundTask without any background refresh task in progress, creating one")
                            #endif
                            self.launchURLSession()
                        }
                    }
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
            let url = URL(string: UrlHelper.getUrl(city))!

            let urlSession = URLSession(configuration: urlSessionConfig, delegate: backgroundSessionDelegate, delegateQueue: OperationQueue.main)
            let downloadTask = urlSession.downloadTask(with: url)
            downloadTask.resume()

            #if DEBUG
                print("downloadTask fired")
            #endif
        } else {
            print("scheduleURLSession - no selected city")
            Task { @MainActor in
                WatchWeatherModel.shared.scheduleRefresh(Constants.backgroundRefreshInSeconds)
            }
        }
    }
}
