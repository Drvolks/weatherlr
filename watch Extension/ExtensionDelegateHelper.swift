//
//  ExtensionDelegateHelper.swift
//  weatherlr
//
//  Created by drvolks on 16-09-21.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation
import WatchKit

class ExtensionDelegateHelper {
    static func launchURLSession() {
        print(WKExtension.shared().delegate)
        guard let delegate = WKExtension.shared().delegate as? ExtensionDelegate else {
            print("launchURLSession: no delegate!")
            return
        }
        
        delegate.launchURLSession()
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
}
