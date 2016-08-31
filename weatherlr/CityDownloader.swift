//
//  CityDownloader.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-21.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class CityDownloader {
    var outputPath:String
    
    init(outputPath:String) {
        self.outputPath = outputPath
    }
    
    func process() {
        let path = Bundle.main.path(forResource: "Cities", ofType: "plist")
        let cities = (NSKeyedUnarchiver.unarchiveObject(withFile: path!) as? [City])!
        
        for i in 0..<cities.count {
            let city = cities[i]
            
            for lang in Language.all {
                let url = UrlHelper.getUrl(city, lang: lang)
                
                if let url = URL(string: url) {
                    load(url, city: city, lang: lang)
                }
            }
        }
    }
    
    func load(_ url: URL, city:City, lang: Language) {
        print("Downloading \(city.frenchName) \(city.province)")
        
        if let data = try? Data(contentsOf: url) {
            let path = outputPath + "/" + city.id + "_" + String(describing: lang) + ".xml"
            try! data.write(to: URL(fileURLWithPath: path), options: Data.WritingOptions.atomicWrite)
        }
    }
}
