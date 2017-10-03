//
//  City.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class City : NSObject, NSCoding {
    var id = ""
    var frenchName = ""
    var englishName = ""
    var province = ""
    var radarId = ""
    
    // MARK: Types
    struct PropertyKey {
        static let frenchNameKey = "frenchName"
        static let englishNameKey = "englishName"
        static let idKey = "id"
        static let provinceKey = "province"
        static let radarKey = "radar"
    }
    
    override init() {
        super.init()
    }
    
    init(id: String, frenchName: String, englishName: String, province: String, radarId: String) {
        self.id = id
        self.frenchName = frenchName
        self.englishName = englishName
        self.province = province
        self.radarId = radarId
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(frenchName, forKey: PropertyKey.frenchNameKey)
        aCoder.encode(englishName, forKey: PropertyKey.englishNameKey)
        aCoder.encode(id, forKey: PropertyKey.idKey)
        aCoder.encode(province, forKey: PropertyKey.provinceKey)
        aCoder.encode(radarId, forKey: PropertyKey.radarKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let frenchName = aDecoder.decodeObject(forKey: PropertyKey.frenchNameKey) as! String
        let englishName = aDecoder.decodeObject(forKey: PropertyKey.englishNameKey) as! String
        let province = aDecoder.decodeObject(forKey: PropertyKey.provinceKey) as! String
        let id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as! String
        var radarId = aDecoder.decodeObject(forKey: PropertyKey.radarKey) as? String
        
        if radarId == nil {
            radarId = ""
        }
        
        self.init(id: id, frenchName: frenchName, englishName: englishName, province: province, radarId: radarId!)
    }
}
