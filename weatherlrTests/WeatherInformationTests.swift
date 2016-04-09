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
        var temperature:Int = 10
        var result = WeatherInformation(temperature: temperature, weatherStatus: .MostlyCloudy, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(temperature, result.temperature)
        XCTAssertEqual(WeatherStatus.MostlyCloudy, result.weatherStatus)
        XCTAssertEqual(WeatherDay.Today, result.weatherDay)
        XCTAssertEqual("sumary", result.summary)
        XCTAssertEqual("detail", result.detail)
        XCTAssertEqual("MostlyCloudy", result.weatherStatusImage.accessibilityIdentifier)
        
        // temperature negatire
        temperature = -10
        result = WeatherInformation(temperature: temperature, weatherStatus: .Sunny, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        XCTAssertNotNil(result)
        XCTAssertEqual(temperature, result.temperature)
        
        // Image inconnue
        result = WeatherInformation(temperature: temperature, weatherStatus: .UnitTest, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        XCTAssertEqual("NA", result.weatherStatusImage.accessibilityIdentifier)
    }
}
