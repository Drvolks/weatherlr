//
//  CityDownloader.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-21.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation
import WeatherFramework

class CityDownloader {
    var outputPath:String
    
    init(outputPath:String) {
        self.outputPath = outputPath
    }
    
    func process() {
        let cities = CityHelper.loadAllCities()
        
        for i in 0..<cities.count {
            let city = cities[i]
            
            for lang in Language.allCases {
                let url = UrlHelper.getUrl(city, lang: lang)
                
                if let url = URL(string: url) {
                    load(url, city: city, lang: lang)
                }
            }
        }
        
        print("Done!")
    }
    
    func load(_ url: URL, city:City, lang: Language) {
        print("Downloading \(city.frenchName) \(city.province)")
        
        if let data = try? Data(contentsOf: url) {
            let path = outputPath + "/" + city.id + "_" + String(describing: lang) + ".xml"
            try! data.write(to: URL(fileURLWithPath: path), options: Data.WritingOptions.atomicWrite)
        }
    }
}
