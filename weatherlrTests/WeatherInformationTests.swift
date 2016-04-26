//
//  WeatherInformationTests.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-04-04.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import XCTest
@testable import weatherlr

class WeatherInformationTests: XCTestCase {
    func testWeatherInformationBaseConstructor() {
        let result = WeatherInformation()
        XCTAssertNotNil(result)
        XCTAssertEqual(0, result.temperature)
        XCTAssertEqual(WeatherStatus.NA, result.weatherStatus)
        XCTAssertEqual(WeatherDay.Now, result.weatherDay)
    }
    
    func testWeatherInformationConstructor() {
        var temperature = 10
        var result = WeatherInformation(temperature: temperature, weatherStatus: .MostlyCloudy, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(temperature, result.temperature)
        XCTAssertEqual(WeatherStatus.MostlyCloudy, result.weatherStatus)
        XCTAssertEqual(WeatherDay.Today, result.weatherDay)
        XCTAssertEqual("sumary", result.summary)
        XCTAssertEqual("detail", result.detail)
        
        // temperature negative
        temperature = -10
        result = WeatherInformation(temperature: temperature, weatherStatus: .Sunny, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(temperature, result.temperature)
    }
    
    func testImage() {
        var bean = WeatherInformation(temperature: 10, weatherStatus: .MostlyCloudy, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        var resultat = bean.image()
        XCTAssertEqual(UIImage(named: "MostlyCloudy"), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .MostlyCloudy, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: true)
        resultat = bean.image()
        XCTAssertEqual(UIImage(named: "MostlyCloudy"), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .PartlyCloudy, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.image()
        XCTAssertEqual(UIImage(named: "PartlyCloudy"), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .PartlyCloudy, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: true)
        resultat = bean.image()
        XCTAssertEqual(UIImage(named: "PartlyCloudyNight"), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .UnitTest, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.image()
        XCTAssertEqual(UIImage(named: "NA"), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .UnitTest, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: true)
        resultat = bean.image()
        XCTAssertEqual(UIImage(named: "NA"), resultat)
    }
    
    func testAllImagesExists() {
        for status in TestUtils.iterateEnum(WeatherStatus) {
            if status != WeatherStatus.UnitTest {
                let result = UIImage(named: String(status))
                if result == nil {
                    print(status)
                }
                XCTAssertNotNil(result)
            }
        }
    }
    
    func testColor() {
        /********************************************** Gris nuage */
        var bean = WeatherInformation(temperature: 10, weatherStatus: .AFewRainShowersOrFlurries, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        var resultat = bean.color()
        XCTAssertEqual(WeatherColor.CloudyDay, resultat)
        
        
        
        /********************************************** Gris neige */
        bean = WeatherInformation(temperature: 10, weatherStatus: .LightSnow, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(WeatherColor.SnowDay, resultat)
        
 
        /********************************************** Beau temps */
        bean = WeatherInformation(temperature: 10, weatherStatus: .Sunny, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(WeatherColor.ClearDay, resultat)
    }
    
    func testAllColorsExists() {
        let defaultColor = WeatherColor.DefaultColor
        
        for status in TestUtils.iterateEnum(WeatherStatus) {
            if status != WeatherStatus.UnitTest {
                let bean = WeatherInformation(temperature: 10, weatherStatus: status, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
                let resultat = bean.color()
                
                if defaultColor == resultat {
                    print(status)
                }
                
                XCTAssertNotEqual(defaultColor, resultat)
            }
        }
    }
}
