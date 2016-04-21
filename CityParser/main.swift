//
//  main.swift
//  CityParser
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

//let provinces = ["AB","BC","PE","MB","NB","NS","NU","ON","QC","SK","NL","NT","YT"]
let provinces = ["BC"]
let lang = ["https://meteo.gc.ca/forecast/canada/index_f.html?id=", "https://weather.gc.ca/forecast/canada/index_e.html?id="]
let parser = CityParser()

for i in 0..<provinces.count {
    for j in 0..<lang.count {
        print("Parsing " + lang[j] + provinces[i])
        
        if let url = NSURL(string: lang[j] + provinces[i]) {
            let content = try! NSString(contentsOfURL: url, usedEncoding: nil)
        
            parser.parse(content as String)
        } else {
            print("Erreur loading " + lang[j] + provinces[i])
        }
    }
}

var cityArray = [City]()
for (_, city) in parser.cities {
    print(String(city.id) + "|" + city.province + "|" + city.frenchName + "|" + city.englishName)
    
    cityArray.append(city)
}

let path = "ParsedCities.plist"
let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(cityArray, toFile: path)
if !isSuccessfulSave {
    print("Error saving cities :(")
}