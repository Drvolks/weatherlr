//
//  TemperatureTest.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-08.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import XCTest
@testable import weatherlr
import WeatherFramework

class TemperatureTests: XCTestCase {
    let testBundle = Bundle(for: TemperatureTests.self)

    func testNoMissingTemperature1() {
        noMissingTemperature("/cities1")
    }
    
    /*
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
 */
    
    func noMissingTemperature(_ subPath: String) {
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
                
                for rssEntry in rssEntries {
                    let performer = RssEntryToWeatherInformation(rssEntry: rssEntry)
                    
                    if performer.isAlert(rssEntry.title) {
                        continue
                    }
                    
                    let weatherDay = performer.convertWeatherDay(rssEntry.category, currentDay: 99)
                    
                    var temperatureText:String
                    var result:Int
                    if weatherDay == WeatherDay.now {
                        temperatureText = performer.extractTemperatureNowFromTitle(rssEntry.title)
                        result = performer.convertTemperature(temperatureText)
                    } else {
                        temperatureText = performer.extractTemperature(rssEntry.title)
                        result = performer.convertTemperatureWithTextSign(temperatureText)
                    }
                    
                    let firstT = temperatureText.index(temperatureText.startIndex, offsetBy: 0)
                    var zero = temperatureText == "zero" || temperatureText == "zéro"
                    if temperatureText != "" && temperatureText[firstT] == "0" {
                        zero = true
                    } else if temperatureText.count > 1 {
                        let secondT = temperatureText.index(temperatureText.startIndex, offsetBy: 2)
                        let temperatureTextSecond = String(temperatureText[..<secondT])
                        if temperatureTextSecond == "-0" {
                            zero = true
                        }
                    }
                    
                    if zero == false {
                        if result == 0 {
                            print("Day: " + String(describing: weatherDay))
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
