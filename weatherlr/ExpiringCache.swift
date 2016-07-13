//
//  ExpiringCache.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-25.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class ExpiringCache : NSCache {
    static let instance = ExpiringCache()
    
    private let ExpiringCacheObjectKey = "expireObjectKey"
    private let ExpiringCacheDefaultTimeout: NSTimeInterval = 60 * Double(Constants.WeatherCacheInMinutes)
    
    override init() {
        super.init()
        countLimit = 10
    }
    
    func setObject(obj: AnyObject, forKey key: AnyObject, timeout: NSTimeInterval) {
        super.setObject(obj, forKey: key)
        NSTimer.scheduledTimerWithTimeInterval(timeout, target: self, selector: #selector(ExpiringCache.timerExpires(_:)), userInfo: [ExpiringCacheObjectKey : key], repeats: false)
    }
    
    override func setObject(obj: AnyObject, forKey key: AnyObject) {
        self.setObject(obj, forKey: key, timeout: ExpiringCacheDefaultTimeout)
    }
    
    func timerExpires(timer: NSTimer) {
        removeObjectForKey(timer.userInfo![ExpiringCacheObjectKey] as! String)
    }
}