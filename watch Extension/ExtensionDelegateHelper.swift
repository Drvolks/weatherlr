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
        delegate().launchURLSession()
    }
    
    static func refreshNeeded() -> Bool {
        return delegate().wrapper.refreshNeeded()
    }
    
    private static func delegate() -> ExtensionDelegate {
        return WKExtension.shared().delegate as! ExtensionDelegate
    }
}
