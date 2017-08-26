//
//  CityParser.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class CityParser {
    var outputPath:String

    var cities = [String:City]()
    let provinces = ["AB","BC","PE","MB","NB","NS","NU","ON","QC","SK","NL","NT","YT"]
    let lang = ["https://meteo.gc.ca/forecast/canada/index_f.html?id=", "https://weather.gc.ca/forecast/canada/index_e.html?id="]
    let weatherUrl1 = "https://meteo.gc.ca/city/pages/"
    let weatherUrl2 = "_metric_f.html"
    
    init(outputPath:String) {
        self.outputPath = outputPath
    }
    
    func perform() {
        for i in 0..<provinces.count {
            for j in 0..<lang.count {
                print("Parsing " + lang[j] + provinces[i])
                
                if let url = URL(string: lang[j] + provinces[i]) {
                    let content = try! NSString(contentsOf: url, usedEncoding: nil)
                    
                    parse(content as String)
                } else {
                    print("Erreur loading " + lang[j] + provinces[i])
                }
            }
        }
        
        var cityArray = [City]()
        for (_, city) in cities {
            print(String(city.id) + "|" + city.province + "|" + city.frenchName + "|" + city.englishName)
            
            cityArray.append(city)
        }
        
        let path = outputPath + "/cities.plist"
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(cityArray, toFile: path)
        
        
        if !isSuccessfulSave {
            print("Error saving cities :(")
        }
    }
    
    func parse(_ data:String) {
        let regex = try! NSRegularExpression(pattern: "/city/pages/(\\w*)-(\\w\\d*)_metric_(f|e).html\">(.*?)<", options: [.caseInsensitive])
        let results = regex.matches(in: data, options: [], range: NSMakeRange(0, data.characters.distance(from: data.startIndex, to: data.endIndex)))
        for i in 0..<results.count {
            let province = (data as NSString).substring(with: results[i].range(at: 1))
            var cityId = (data as NSString).substring(with: results[i].range(at: 2))
            let lang = (data as NSString).substring(with: results[i].range(at: 3))
            let cityName = (data as NSString).substring(with: results[i].range(at: 4))
            
            cityId = province + "-" + cityId
            
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
            
            let radarId = getRadarId(cityId)
            city.radarId = radarId
        }
    }
    
    func getRadarId(_ cityId:String) -> String {
        // TODO caching resultat car le même pour français et anglais
        let urlStr = weatherUrl1 + cityId + weatherUrl2
        if let url = URL(string: urlStr) {
            let content = try! NSString(contentsOf: url, usedEncoding: nil) as String
            
            let regex = try! NSRegularExpression(pattern: "\"/radar/index_f.html\\?id=(.*?)\"", options: [.caseInsensitive])
            let results = regex.matches(in: content, options: [], range: NSMakeRange(0, content.characters.distance(from: content.startIndex, to: content.endIndex)))
            
            if results.count > 0 {
                let radarId = (content as NSString).substring(with: results[0].range(at: 1))
                
                return radarId
            }
        }
        
        return ""
    }
}
