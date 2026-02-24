//
//  ExtensionDelegateHelper.swift
//  weatherlr
//
//  Created by drvolks on 16-09-21.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation
import WatchKit
import WidgetKit

@MainActor
class ExtensionDelegateHelper {
    static func launchURLSessionNow(_ delegate: URLSessionDelegate) {
        #if DEBUG
            print("launchURLSessionNow")
        #endif

        let city = PreferenceHelper.getCityToUse()
        
        #if DEBUG
            print("launchURLSessionNow " + city.frenchName)
        #endif
        
        if !LocationServices.isUseCurrentLocation(city) {
            let url = URL(string:UrlHelper.getUrl(city))!
            
            let configObject = URLSessionConfiguration.default
            configObject.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            let session = URLSession(configuration: configObject, delegate: delegate, delegateQueue: OperationQueue.main)
            
            let downloadTask = session.downloadTask(with: url)
            downloadTask.resume()
        } else {
            print("scheduleURLSession - no selected city")
        }
    }
    
    static func refreshNeeded() -> Bool {
        guard let delegate = WKApplication.shared().delegate as? ExtensionDelegate else {
            print("refreshNeeded: no delegate!")
            return true
        }
        
        return delegate.wrapper.refreshNeeded()
    }
    
    static func resetWeather() {
        guard let delegate = WKApplication.shared().delegate as? ExtensionDelegate else {
            print("resetWeather: no delegate!")
            return
        }
        
        delegate.wrapper = WeatherInformationWrapper()
    }
    
    static func getWrapper() -> WeatherInformationWrapper {
        guard let delegate = WKApplication.shared().delegate as? ExtensionDelegate else {
            print("getWrapper: no delegate!")
            return WeatherInformationWrapper()
        }
        
        return delegate.wrapper
    }
    
    static func setWrapper(_ wrapper: WeatherInformationWrapper) {
        guard let delegate = WKApplication.shared().delegate as? ExtensionDelegate else {
            print("getWrapper: no delegate!")
            return
        }
        
        return delegate.wrapper = wrapper
    }
    
    static func updateComplication() {
        #if DEBUG
            print("updateComplication")
        #endif

        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func scheduleRefresh(_ backgroundRefreshInSeconds:Double) {
        #if DEBUG
            print("scheduleRefresh")
        #endif
        
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: backgroundRefreshInSeconds), userInfo: nil) { (error: Error?) in
            if let error = error {
                print("Error occured while calling scheduleBackgroundRefresh: \(error.localizedDescription)")
            }
        }
    }
}
