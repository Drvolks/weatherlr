//
//  TemperatureTest.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import XCTest
@testable import weatherlr


class TemperatureTests: XCTestCase {
    let testBundle = NSBundle(forClass: TemperatureTests.self)

    func testNoMissingTemperature1() {
        noMissingTemperature("/cities1")
    }
    
    func testNoMissingTemperature2() {
        noMissingTemperature("/cities2")
    }
    
    func testNoMissingTemperature3() {
        noMissingTemperature("/cities3")
    }
    
    func testNoMissingTemperature4() {
        noMissingTemperature("/cities4")
    }
    
    func testNoMissingTemperature5() {
        noMissingTemperature("/cities5")
    }
    
    
    func noMissingTemperature(subPath: String) {
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
                
                for rssEntry in rssEntries {
                    let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
                    
                    if performer.isAlert(rssEntry.title) {
                        continue
                    }
                    
                    let weatherDay = performer.convertWeatherDay(rssEntry.category, currentDay: 99)
                    
                    var temperatureText:String
                    var result:Int
                    if weatherDay == WeatherDay.Now {
                        temperatureText = performer.extractTemperatureNowFromTitle(rssEntry.title)
                        result = performer.convertTemperature(temperatureText)
                    } else {
                        temperatureText = performer.extractTemperature(rssEntry.title)
                        result = performer.convertTemperatureWithTextSign(temperatureText)
                    }
                    
                    let firstT = temperatureText.startIndex.advancedBy(0)
                    var zero = temperatureText == "zero" || temperatureText == "zéro"
                    if temperatureText != "" && temperatureText[firstT] == "0" {
                        zero = true
                    } else if temperatureText.characters.count > 1 {
                        let secondT = temperatureText.startIndex.advancedBy(2)
                        if temperatureText.substringToIndex(secondT) == "-0" {
                            zero = true
                        }
                    }
                    
                    if zero == false {
                        if result == 0 {
                            print("Day: " + String(weatherDay))
                            print("Title: " + rssEntry.title)
                            print("Temperature text: " + temperatureText)
                        }
                        
                        XCTAssertNotEqual(0, result)
                    }
                }
            }
        }
    }
}