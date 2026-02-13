//
//  ExpiringCache.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-25.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class ExpiringCache<T> {
    private var cache = [String: T]()
    private let lock = NSLock()
    private let defaultTimeout: TimeInterval = 60 * Double(Global.weatherCacheInMinutes)

    func object(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return cache[key]
    }

    func setObject(_ obj: T, forKey key: String, timeout: TimeInterval? = nil) {
        lock.lock()
        cache[key] = obj
        lock.unlock()

        let effectiveTimeout = timeout ?? defaultTimeout
        Timer.scheduledTimer(withTimeInterval: effectiveTimeout, repeats: false) { [weak self] _ in
            self?.removeObject(forKey: key)
        }
    }

    func removeObject(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeValue(forKey: key)
    }

    func removeAllObjects() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}
