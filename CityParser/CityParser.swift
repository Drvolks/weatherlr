//
//  CityParser.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class CityParser {
    var cities = [Int:City]()
    
    func parse(data:String) {
        let regex = try! NSRegularExpression(pattern: "/city/pages/(\\w*)-(\\d*)_metric_(f|e).html\">(.*?)<", options: [.CaseInsensitive])
        let results = regex.matchesInString(data, options: [], range: NSMakeRange(0, data.startIndex.distanceTo(data.endIndex)))
        for i in 0..<results.count {
            let province = (data as NSString).substringWithRange(results[i].rangeAtIndex(1))
            let cityId = Int((data as NSString).substringWithRange(results[i].rangeAtIndex(2)))!
            let lang = (data as NSString).substringWithRange(results[i].rangeAtIndex(3))
            let cityName = (data as NSString).substringWithRange(results[i].rangeAtIndex(4))
            
            let city:City
            if let cityTest = cities[cityId] {
                city = cityTest
            } else {
                city = City()
                city.id = cityId
                city.province = province
                
                cities[cityId] = city
            }
            
            if lang == "f" {
                city.frenchName = cityName
            } else {
                city.englishName = cityName
            }
        }
    }
}