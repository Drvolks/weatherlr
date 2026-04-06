//
//  ExpiringCache.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-25.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

class ExpiringCache<T>: @unchecked Sendable {
    private var cache = [String: (value: T, expiration: Date)]()
    private let lock = NSLock()
    private let defaultTimeout: TimeInterval = 60 * Double(Global.weatherCacheInMinutes)

    func object(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }

        guard let entry = cache[key] else { return nil }

        if Date() >= entry.expiration {
            cache.removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    func setObject(_ obj: T, forKey key: String, timeout: TimeInterval? = nil) {
        let effectiveTimeout = timeout ?? defaultTimeout
        let expiration = Date().addingTimeInterval(effectiveTimeout)

        lock.lock()
        defer { lock.unlock() }
        cache[key] = (value: obj, expiration: expiration)
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
