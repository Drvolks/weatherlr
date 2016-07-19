//
//  ExpiringCache.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-25.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class ExpiringCache : Cache<AnyObject, AnyObject> {
    static let instance = ExpiringCache()
    
    private let ExpiringCacheObjectKey = "expireObjectKey"
    private let ExpiringCacheDefaultTimeout: TimeInterval = 60 * Double(Constants.WeatherCacheInMinutes)
    
    override init() {
        super.init()
        countLimit = 10
    }
    
    func setObject(_ obj: AnyObject, forKey key: AnyObject, timeout: TimeInterval) {
        super.setObject(obj, forKey: key)
        Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(ExpiringCache.timerExpires(_:)), userInfo: [ExpiringCacheObjectKey : key], repeats: false)
    }
    
    override func setObject(_ obj: AnyObject, forKey key: AnyObject) {
         self.setObject(obj, forKey: key, timeout: ExpiringCacheDefaultTimeout)
    }
    
    func timerExpires(_ timer: Timer) {
        removeObject(forKey: timer.userInfo![ExpiringCacheObjectKey] as! String)
    }
}
