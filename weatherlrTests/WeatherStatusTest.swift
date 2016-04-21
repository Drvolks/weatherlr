//
//  WeatherStatusTest.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-21.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import XCTest
@testable import weatherlr

class WeatherStatusTests: XCTestCase {
    let testBundle = NSBundle(forClass: WeatherStatusTests.self)
    
    func testNoMissingStatusFrench() {
        noMissingStatusFrench("/cities_fr", lang: Language.French)
    }
    
    func testNoMissingStatusEnglish() {
        noMissingStatusFrench("/cities_en", lang: Language.English)
    }
    
    func noMissingStatusFrench(subPath: String, lang: Language) {
        let fileManager = NSFileManager.defaultManager()
        let path = testBundle.resourcePath!
        let items = try! fileManager.contentsOfDirectoryAtPath(path + subPath)
        for item in items {
            let url = NSURL(fileURLWithPath: item)
            let baseName = url.URLByDeletingPathExtension?.lastPathComponent!
            
            if let file = testBundle.pathForResource(subPath + "/" + baseName!, ofType: "xml")
            {
                let xmlData = NSData(contentsOfFile: file)!
                let parser = RssParser(xmlData: xmlData, language: lang)
                
                let rssEntries = parser.parse()
                let converter = RssEntryToWeatherInformation(rssEntries: rssEntries)
                let weatherInfos = converter.perform()
                
                for weatherInfo in weatherInfos {
                    if WeatherStatus.NA == weatherInfo.weatherStatus {
                        if weatherInfo.weatherDay == WeatherDay.Now {
                            print("Detail: " + weatherInfo.detail)
                        } else {
                            print("Summary: " + weatherInfo.summary)
                        }
                    }
                    
                    XCTAssertNotEqual(WeatherStatus.NA, weatherInfo.weatherStatus)
                }
            }
        }
    }
}