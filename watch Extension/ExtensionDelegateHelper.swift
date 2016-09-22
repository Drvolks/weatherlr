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
}
