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
        delegate().launchURLSession()
    }
    
    static func refreshNeeded() -> Bool {
        return delegate().wrapper.refreshNeeded()
    }
    
    private static func delegate() -> ExtensionDelegate {
        return WKExtension.shared().delegate as! ExtensionDelegate
    }
}
