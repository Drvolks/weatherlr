//
//  TestReadPlist.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class TestReadPlist {
    func test() {
        let path = "Cities.plist"
        let cities = (NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? [City])!
        
        for i in 0..<cities.count {
            print(cities[i].frenchName)
        }
    }
}