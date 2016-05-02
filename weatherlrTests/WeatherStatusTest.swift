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
        noMissingStatus("/cities_fr", lang: Language.French)
    }
    
    func testNoMissingStatusEnglish() {
        noMissingStatus("/cities_en", lang: Language.English)
    }
    
    func testNoMissingStatus1() {
        noMissingStatus("/cities")
    }
    
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
    
    func noMissingStatus(subPath: String) {
        let fileManager = NSFileManager.defaultManager()
        let path = testBundle.resourcePath!
        let items = try! fileManager.contentsOfDirectoryAtPath(path + subPath)
        for item in items {
            let url = NSURL(fileURLWithPath: item)
            let baseName = url.URLByDeletingPathExtension?.lastPathComponent!
            
            if let file = testBundle.pathForResource(subPath + "/" + baseName!, ofType: "xml")
            {
                var lang = Language.French
                if file.containsString(String(Language.English)) {
                    lang = Language.English
                }
                
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
    
    func noMissingStatus(subPath: String, lang: Language) {
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