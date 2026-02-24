//
//  BackgroundSessionDelegate.swift
//  watch Extension
//
//  Created by Jean-Francois Dufour on 2026-02-24.
//  Copyright © 2026 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit

class BackgroundSessionDelegate: NSObject, URLSessionDelegate, URLSessionDownloadDelegate, @unchecked Sendable {
    var savedTask: WKRefreshBackgroundTask?

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        #if DEBUG
            print("urlSession didFinishDownloadingTo")
        #endif

        let city = PreferenceHelper.getCityToUse()
        if !LocationServices.isUseCurrentLocation(city) {
            do {
                let jsonData = try Data(contentsOf: location)
                let wrapper = WeatherHelper.getWeatherInformationsNoCache(jsonData, city: city)

                Task { @MainActor in
                    let model = WatchWeatherModel.shared
                    model.wrapper = wrapper

                    #if DEBUG
                        print("wrapper updated")
                    #endif

                    model.updateComplication()
                }
            } catch {
                print("Error info: \(error)")
                Task { @MainActor in
                    WatchWeatherModel.shared.launchURLSessionNow()
                }
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
                print("savedTask completed")
            #endif
        }

        Task { @MainActor in
            WatchWeatherModel.shared.scheduleRefresh(Constants.backgroundRefreshInSeconds)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        #if DEBUG
            print("urlSession didCompleteWithError")
        #endif

        if let error = error {
            print(error)
            Task { @MainActor in
                WatchWeatherModel.shared.scheduleRefresh(5.0 * 60.0)
            }
        }

        if let task = savedTask {
            task.setTaskCompletedWithSnapshot(true)
            savedTask = nil

            #if DEBUG
                print("savedTask completed in didCompleteWithError")
            #endif
        }
    }
}
