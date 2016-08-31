//
//  TestUtils.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-21.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

class TestUtils {
    static func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
        var i = 0
        return AnyIterator {
            let next = withUnsafePointer(to: &i) {
                $0.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
            }
            if next.hashValue != i { return nil }
            i += 1
            return next
        }
    }
}
