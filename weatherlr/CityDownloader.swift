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
        let path = NSBundle.mainBundle().pathForResource("Cities", ofType: "plist")
        let cities = (NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as? [City])!
        
        for i in 0..<cities.count {
            let city = cities[i]
            
            for lang in Language.all {
                let url = UrlHelper.getUrl(city, lang: lang)
                
                if let url = NSURL(string: url) {
                    load(url, city: city, lang: lang)
                }
            }
        }
    }
    
    func load(url: NSURL, city:City, lang: Language) {
        print("Downloading \(city.frenchName) \(city.province)")
        
        if let data = NSData(contentsOfURL: url) {
            let path = outputPath + "/" + city.id + "_" + String(lang) + ".xml"
            try! data.writeToFile(path, options: NSDataWritingOptions.AtomicWrite)
        }
    }
}