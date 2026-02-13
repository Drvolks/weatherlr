//
//  City.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

public struct City: Codable, Sendable, Equatable, Hashable {
    public var id = ""
    public var frenchName = ""
    public var englishName = ""
    public var province = ""
    public var radarId = ""
    public var latitude = ""
    public var longitude = ""

    public init() {}

    public init(id: String, frenchName: String, englishName: String, province: String, radarId: String, latitude: String, longitude: String) {
        self.id = id
        self.frenchName = frenchName
        self.englishName = englishName
        self.province = province
        self.radarId = radarId
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Legacy NSCoding support for migration

public class LegacyCity: NSObject, NSCoding {
    public var id = ""
    public var frenchName = ""
    public var englishName = ""
    public var province = ""
    public var radarId = ""
    public var latitude = ""
    public var longitude = ""

    private struct PropertyKey {
        static let frenchNameKey = "frenchName"
        static let englishNameKey = "englishName"
        static let idKey = "id"
        static let provinceKey = "province"
        static let radarKey = "radar"
        static let latitudeKey = "latitude"
        static let longitudeKey = "longitude"
    }

    public override init() {
        super.init()
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(frenchName, forKey: PropertyKey.frenchNameKey)
        aCoder.encode(englishName, forKey: PropertyKey.englishNameKey)
        aCoder.encode(id, forKey: PropertyKey.idKey)
        aCoder.encode(province, forKey: PropertyKey.provinceKey)
        aCoder.encode(radarId, forKey: PropertyKey.radarKey)
        aCoder.encode(latitude, forKey: PropertyKey.latitudeKey)
        aCoder.encode(longitude, forKey: PropertyKey.longitudeKey)
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        self.init()
        self.frenchName = aDecoder.decodeObject(forKey: PropertyKey.frenchNameKey) as? String ?? ""
        self.englishName = aDecoder.decodeObject(forKey: PropertyKey.englishNameKey) as? String ?? ""
        self.province = aDecoder.decodeObject(forKey: PropertyKey.provinceKey) as? String ?? ""
        self.id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? String ?? ""
        self.radarId = aDecoder.decodeObject(forKey: PropertyKey.radarKey) as? String ?? ""
        self.latitude = aDecoder.decodeObject(forKey: PropertyKey.latitudeKey) as? String ?? ""
        self.longitude = aDecoder.decodeObject(forKey: PropertyKey.longitudeKey) as? String ?? ""
    }

    public func toCity() -> City {
        City(id: id, frenchName: frenchName, englishName: englishName, province: province, radarId: radarId, latitude: latitude, longitude: longitude)
    }

    public static func registerClassMappings() {
        NSKeyedUnarchiver.setClass(LegacyCity.self, forClassName: "City")
        NSKeyedUnarchiver.setClass(LegacyCity.self, forClassName: "weatherlr.City")
        NSKeyedUnarchiver.setClass(LegacyCity.self, forClassName: "weatherlrFree.City")
        NSKeyedUnarchiver.setClass(LegacyCity.self, forClassName: "WeatherFramework.City")
    }
}
