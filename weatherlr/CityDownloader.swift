//
//  CityDownloader.swift
//  weatherlr
//
//  Created by drvolks on 2016-04-21.
//  Copyright © 2016 drvolks. All rights reserved.
//

import Foundation

class CityDownloader {
    var outputPath:String
    
    init(outputPath:String) {
        self.outputPath = outputPath
    }
    
    func process() {
        let cities = CityHelper.loadAllCities()

        for i in 0..<cities.count {
            let city = cities[i]
            let url = UrlHelper.getUrl(city)

            if let url = URL(string: url) {
                load(url, city: city)
            }
        }

        print("Done!")
    }

    func load(_ url: URL, city:City) {
        print("Downloading \(city.frenchName) \(city.province)")

        if let data = try? Data(contentsOf: url) {
            let path = outputPath + "/" + city.id + ".json"
            try! data.write(to: URL(fileURLWithPath: path), options: Data.WritingOptions.atomicWrite)
        }
    }
}
