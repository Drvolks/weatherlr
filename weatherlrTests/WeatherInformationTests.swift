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
        XCTAssertEqual(WeatherStatus.na, result.weatherStatus)
        XCTAssertEqual(WeatherDay.now, result.weatherDay)
    }
    
    func testWeatherInformationConstructor() {
        var temperature = 10
        var result = WeatherInformation(temperature: temperature, weatherStatus: .mostlyCloudy, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(temperature, result.temperature)
        XCTAssertEqual(WeatherStatus.mostlyCloudy, result.weatherStatus)
        XCTAssertEqual(WeatherDay.today, result.weatherDay)
        XCTAssertEqual("sumary", result.summary)
        XCTAssertEqual("detail", result.detail)
        
        // temperature negative
        temperature = -10
        result = WeatherInformation(temperature: temperature, weatherStatus: .sunny, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(temperature, result.temperature)
    }
    
    func testImage() {
        var bean = WeatherInformation(temperature: 10, weatherStatus: .mostlyCloudy, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: false)
        var resultat = bean.image()
        XCTAssertEqual(UIImage(named: "mostlyCloudy"), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .mostlyCloudy, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: true)
        resultat = bean.image()
        XCTAssertEqual(UIImage(named: "mostlyCloudy"), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .partlyCloudy, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: false)
        resultat = bean.image()
        XCTAssertEqual(UIImage(named: "aFewClouds"), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .partlyCloudy, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: true)
        resultat = bean.image()
        XCTAssertEqual(UIImage(named: "aFewCloudsNight"), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .unitTest, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: false)
        resultat = bean.image()
        XCTAssertEqual(UIImage(named: "na"), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .unitTest, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: true)
        resultat = bean.image()
        XCTAssertEqual(UIImage(named: "na"), resultat)
    }
    
    func testAllImagesExists() {
        let defaultImage = UIImage(named: String(describing: WeatherStatus.na))
        
        var nb = 0
        
        for status in TestUtils.iterateEnum(WeatherStatus.self) {
            nb = nb + 1
            
            if status != WeatherStatus.unitTest && status != WeatherStatus.na {
                // day
                var bean = WeatherInformation(temperature: 10, weatherStatus: status, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: false)
                
                var result = bean.image()
                if result == defaultImage {
                    print(status)
                }
                XCTAssertNotEqual(defaultImage, result)
                
                // night
                bean = WeatherInformation(temperature: 10, weatherStatus: status, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: true)
                
                result = bean.image()
                if result == defaultImage {
                    print(status)
                }
                XCTAssertNotEqual(defaultImage, result)
            }
        }
        
        XCTAssertTrue(nb > 0)
    }
    
    func testColor() {
        /********************************************** Gris nuage */
        var bean = WeatherInformation(temperature: 10, weatherStatus: .aFewRainShowersOrFlurries, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: false)
        var resultat = bean.color()
        XCTAssertEqual(WeatherColor.cloudyDay, resultat)
        
        
        
        /********************************************** Gris neige */
        bean = WeatherInformation(temperature: 10, weatherStatus: .lightSnow, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(WeatherColor.snowDay, resultat)
        
 
        /********************************************** Beau temps */
        bean = WeatherInformation(temperature: 10, weatherStatus: .sunny, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(WeatherColor.clearDay, resultat)
    }
    
    func testAllColorsExists() {
        let defaultColor = WeatherColor.defaultColor
        
        var nb = 0
        
        for status in TestUtils.iterateEnum(WeatherStatus.self) {
            nb = nb + 1
            
            if status != WeatherStatus.unitTest {
                let bean = WeatherInformation(temperature: 10, weatherStatus: status, weatherDay: .today, summary: "sumary", detail: "detail", tendancy: Tendency.na, when: "", night: false)
                let resultat = bean.color()
                
                if defaultColor == resultat {
                    print(status)
                }
                
                XCTAssertNotEqual(defaultColor, resultat)
            }
        }
        
        XCTAssertTrue(nb > 0)
    }
}
