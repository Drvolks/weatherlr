//
//  City.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class City : NSObject, NSCoding {
    var id = -1
    var frenchName = ""
    var englishName = ""
    var province = ""
    
    // MARK: Types
    struct PropertyKey {
        static let frenchNameKey = "frenchName"
        static let englishNameKey = "englishName"
        static let idKey = "id"
        static let provinceKey = "province"
    }
    
    override init() {
        super.init()
    }
    
    init(id: Int, frenchName: String, englishName: String, province: String) {
        self.id = id
        self.frenchName = frenchName
        self.englishName = englishName
        self.province = province
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(frenchName, forKey: PropertyKey.frenchNameKey)
        aCoder.encodeObject(englishName, forKey: PropertyKey.englishNameKey)
        aCoder.encodeInteger(id, forKey: PropertyKey.idKey)
        aCoder.encodeObject(province, forKey: PropertyKey.provinceKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let frenchName = aDecoder.decodeObjectForKey(PropertyKey.frenchNameKey) as! String
        let englishName = aDecoder.decodeObjectForKey(PropertyKey.englishNameKey) as! String
        let province = aDecoder.decodeObjectForKey(PropertyKey.provinceKey) as! String
        let id = aDecoder.decodeIntegerForKey(PropertyKey.idKey)
        
        self.init(id: id, frenchName: frenchName, englishName: englishName, province: province)
    }
}
