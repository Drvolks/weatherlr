//
//  TestUtils.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-21.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class TestUtils {
    static func iterateEnum<T: Hashable>(_: T.Type) -> AnyGenerator<T> {
        var i = 0
        return AnyGenerator {
            let next = withUnsafePointer(&i) { UnsafePointer<T>($0).memory }
            
            if next.hashValue == i {
                i += 1
                return next
            } else {
                return nil
            }
        }
    }
}