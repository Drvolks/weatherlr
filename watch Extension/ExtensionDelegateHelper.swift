//
//  ExtensionDelegateHelper.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 16-09-21.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WatchKit

class ExtensionDelegateHelper {
    static func launchURLSessionNow(_ delegate: URLSessionDelegate) {
        #if DEBUG
            print("launchURLSessionNow")
        #endif
        
        guard let extensionDelegate = WKExtension.shared().delegate as? ExtensionDelegate else {
            print("launchURLSessionNow: no delegate!")
            return
        }
        
        if let city = getSelectedCity() {
            //extensionDelegate.scheduleRefresh(Constants.backgroundRefreshInSeconds)
            
            let url = URL(string:UrlHelper.getUrl(city))!
            
            let configObject = URLSessionConfiguration.default
            let session = URLSession(configuration: configObject, delegate: delegate, delegateQueue:nil)
            
            let downloadTask = session.downloadTask(with: url)
            downloadTask.resume()
        } else {
            print("scheduleURLSession - no selected city")
        }
    }
    
    static func getSelectedCity() -> City? {
        guard let extensionDelegate = WKExtension.shared().delegate as? ExtensionDelegate else {
            print("getSelectedCity: no delegate!")
            return nil
        }
        
        return extensionDelegate.selectedCity
    }
    
    static func setSelectedCity(_ city:City?) {
        guard let extensionDelegate = WKExtension.shared().delegate as? ExtensionDelegate else {
            print("setSelectedCity: no delegate!")
            return
        }
        
        extensionDelegate.selectedCity = city
    }
    
    static func refreshNeeded() -> Bool {
        guard let delegate = WKExtension.shared().delegate as? ExtensionDelegate else {
            print("refreshNeeded: no delegate!")
            return true
        }
        
        return delegate.wrapper.refreshNeeded()
    }
    
    static func resetWeather() {
        guard let delegate = WKExtension.shared().delegate as? ExtensionDelegate else {
            print("resetWeather: no delegate!")
            return
        }
        
        delegate.wrapper = WeatherInformationWrapper()
    }
    
    static func getWrapper() -> WeatherInformationWrapper {
        guard let delegate = WKExtension.shared().delegate as? ExtensionDelegate else {
            print("getWrapper: no delegate!")
            return WeatherInformationWrapper()
        }
        
        return delegate.wrapper
    }
    
    static func setWrapper(_ wrapper: WeatherInformationWrapper) {
        guard let delegate = WKExtension.shared().delegate as? ExtensionDelegate else {
            print("getWrapper: no delegate!")
            return
        }
        
        return delegate.wrapper = wrapper
    }
    
    static func updateComplication() {
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
