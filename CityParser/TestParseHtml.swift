//
//  TestParseHtml.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-07.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import Foundation

class TestParseHtml {
    func test() {
        let bundle = NSBundle.mainBundle()
        var path = bundle.pathForResource("cities", ofType: "html")
        var content = try! String(contentsOfFile: path!)
        let parser = CityParser()
        parser.parse(content)
        
        path = bundle.pathForResource("cities_en", ofType: "html")
        content = try! String(contentsOfFile: path!)
        parser.parse(content)
        
        for (_, city) in parser.cities {
            print(String(city.id) + "|" + city.province + "|" + city.frenchName + "|" + city.englishName)
        }

    }
}