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
    let testBundle = Bundle(for: WeatherStatusTests.self)
 
    func testNoMissingStatus1() {
        noMissingStatus("/cities1")
    }
  
    /*
    func testNoMissingStatus2() {
        noMissingStatus("/cities2")
    }
    
    func testNoMissingStatus3() {
        noMissingStatus("/cities3")
    }
    
    func testNoMissingStatus4() {
        noMissingStatus("/cities4")
    }
    
    func testNoMissingStatus5() {
        noMissingStatus("/cities5")
    }
    */
    
    func noMissingStatus(_ subPath: String) {
        let fileManager = FileManager.default
        let path = testBundle.resourcePath!
        let items = try! fileManager.contentsOfDirectory(atPath: path + subPath)
        for item in items {
            let url = URL(fileURLWithPath: item)
            let baseName = url.deletingPathExtension().lastPathComponent
            
            if let file = testBundle.path(forResource: subPath + "/" + baseName, ofType: "xml")
            {
                var lang = Language.French
                if file.contains(String(describing: Language.English)) {
                    lang = Language.English
                }
                
                let xmlData = try! Data(contentsOf: URL(fileURLWithPath: file))
                let parser = RssParser(xmlData: xmlData, language: lang)
                
                let rssEntries = parser.parse()
                let converter = RssEntryToWeatherInformation(rssEntries: rssEntries)
                let weatherInfos = converter.perform()
                
                for weatherInfo in weatherInfos {
                    if WeatherStatus.na == weatherInfo.weatherStatus {
                        if weatherInfo.weatherDay == WeatherDay.now {
                            print("Detail: " + weatherInfo.detail)
                        } else {
                            print("Summary: " + weatherInfo.summary)
                        }
                    }
                    
                    XCTAssertNotEqual(WeatherStatus.na, weatherInfo.weatherStatus)
                }
            }
        }
    }
    
    func testNoMissingStatusOneFile() {
        let baseName = "test"
            
        if let file = testBundle.path(forResource: baseName, ofType: "xml")
        {
            var lang = Language.French
            if file.contains(String(describing: Language.English)) {
                lang = Language.English
            }
                
            let xmlData = try! Data(contentsOf: URL(fileURLWithPath: file))
            let parser = RssParser(xmlData: xmlData, language: lang)
                
            let rssEntries = parser.parse()
            let converter = RssEntryToWeatherInformation(rssEntries: rssEntries)
            let weatherInfos = converter.perform()
                
            for weatherInfo in weatherInfos {
                if WeatherStatus.na == weatherInfo.weatherStatus {
                    if weatherInfo.weatherDay == WeatherDay.now {
                        print("Detail: " + weatherInfo.detail)
                    } else {
                        print("Summary: " + weatherInfo.summary)
                    }
                }
                    
                XCTAssertNotEqual(WeatherStatus.na, weatherInfo.weatherStatus)
            }
        }
    }
}
