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
        
        // temperature negatire
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
    
    func testColor() {
        /********************************************** Gris nuage */
        var bean = WeatherInformation(temperature: 10, weatherStatus: .AFewRainShowersOrFlurries, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        var resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .AFewRainShowersOrFlurries, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: true)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyNight), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .AFewRainShowersOrFlurries, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .ChanceOfRainShowersOrFlurries, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .ChanceOfShowers, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .Cloudy, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .CloudyWithXPercentChanceOfFlurries, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .LightRain, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .Mist, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .MostlyCloudy, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .PeriodsOfRain, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .PeriodsOfRainOrSnow, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .Rain, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .RainAtTimesHeavy, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .RainShowersOrFlurries, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .Showers, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .SnowOrRain, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.CloudyDay), resultat)

        
        /********************************************** Gris neige */
        bean = WeatherInformation(temperature: 10, weatherStatus: .AFewFlurries, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.SnowDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .AFewFlurries, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: true)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.SnowNight), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .ChanceOfFlurries, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.SnowDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .LightSnow, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.SnowDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .PeriodsOfSnow, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.SnowDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .Snow, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.SnowDay), resultat)
        
 
        /********************************************** Beau temps */
        bean = WeatherInformation(temperature: 10, weatherStatus: .Sunny, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: false)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.ClearDay), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .Sunny, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: true)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.ClearNight), resultat)
        
        bean = WeatherInformation(temperature: 10, weatherStatus: .Clear, weatherDay: .Today, summary: "sumary", detail: "detail", tendancy: Tendency.NA, when: "", night: true)
        resultat = bean.color()
        XCTAssertEqual(UIColor(weatherColor:WeatherColor.ClearNight), resultat)
    }
}
